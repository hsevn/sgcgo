import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class OdooApiService {
  final String _odooUrl = 'https://hsevn.com.vn';
  final String _dbName = 'sgc_pro';

  // Biến để lưu trữ "giấy thông hành" sau khi đăng nhập
  String? _sessionId;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_odooUrl/web/session/authenticate');
    final payload = json.encode({
      'jsonrpc': '2.0',
      'params': {'db': _dbName, 'login': email, 'password': password},
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      final responseBody = json.decode(response.body);

      if (responseBody.containsKey('error')) {
        throw Exception(responseBody['error']['message']);
      }

      if (response.statusCode == 200 && responseBody.containsKey('result')) {
        // --- NÂNG CẤP: LẤY VÀ LƯU LẠI SESSION ID ---
        final String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          _sessionId =
              RegExp(r'session_id=([^;]+)').firstMatch(rawCookie)?.group(1);
          print('✅ Đăng nhập thành công! Session ID đã được lưu.');
        }
        // -----------------------------------------
        return responseBody['result'];
      } else {
        throw Exception('Lỗi từ máy chủ: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
          'Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại kết nối mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  /// === HÀM MỚI: Lấy danh sách công việc ===
  ///
  /// Sử dụng phương thức 'search_read' của Odoo để tìm và đọc các công việc.
  Future<List<dynamic>> getTasks() async {
    if (_sessionId == null) {
      throw Exception('Người dùng chưa đăng nhập hoặc phiên đã hết hạn.');
    }

    final url = Uri.parse('$_odooUrl/web/dataset/search_read');
    final payload = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        // Model trong Odoo chứa các công việc, thường là 'project.task'
        'model': 'project.task',
        // Lọc các công việc của người dùng hiện tại (sẽ được Odoo tự động xử lý qua session)
        'domain': [],
        // Các trường thông tin muốn lấy về, bạn có thể tùy chỉnh
        'fields': ['id', 'name', 'project_id', 'partner_id', 'date_deadline'],
        'limit': 80, // Giới hạn số lượng công việc lấy về
      }
    });

    print('🚀 Đang lấy danh sách công việc từ Odoo...');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Gửi kèm "giấy thông hành" để Odoo biết chúng ta là ai
          'Cookie': 'session_id=$_sessionId',
        },
        body: payload,
      );

      final responseBody = json.decode(response.body);

      if (responseBody.containsKey('error')) {
        throw Exception(responseBody['error']['data']['message']);
      }

      if (response.statusCode == 200 && responseBody.containsKey('result')) {
        final List<dynamic> records = responseBody['result']['records'];
        print('✅ Lấy thành công ${records.length} công việc.');
        return records;
      } else {
        throw Exception('Không thể lấy dữ liệu công việc.');
      }
    } on SocketException {
      throw Exception('Lỗi mạng khi lấy dữ liệu công việc.');
    } catch (e) {
      throw Exception('Lỗi không xác định: ${e.toString()}');
    }
  }
}

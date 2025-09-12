import 'dart:convert';
import 'package:http/http.dart' as http;

class OdooApiService {
  // --- THAY ĐỔI CÁC THÔNG SỐ NÀY CHO PHÙ HỢP VỚI ODOO CỦA BẠN ---
  final String _odooUrl =
      'https://hsevn.com.vn'; // Ví dụ: https://mycompany.odoo.com
  final String _dbName = 'sgc_pro'; // Tên database Odoo của bạn
  // ---------------------------------------------------------

  // Hàm để đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_odooUrl/web/session/authenticate');

    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'db': _dbName,
        'login': email,
        'password': password,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          // Odoo trả về lỗi (sai mật khẩu,...)
          throw Exception(data['error']['message']);
        }
        // Đăng nhập thành công, trả về dữ liệu người dùng
        return data['result'];
      } else {
        // Lỗi kết nối mạng
        throw Exception('Lỗi kết nối đến server: ${response.statusCode}');
      }
    } catch (e) {
      // Các lỗi khác (không có mạng, sai domain,...)
      throw Exception(
          'Không thể đăng nhập. Vui lòng kiểm tra lại kết nối và thông tin.');
    }
  }

  // (Sau này chúng ta sẽ thêm các hàm khác như getTasks, sendReport,... vào đây)
}

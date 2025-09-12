import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OdooApiService {
  static final OdooApiService _instance = OdooApiService._internal();
  factory OdooApiService() => _instance;
  OdooApiService._internal();

  // Đổi tên DB của bạn tại đây
  final String _database = 'sgc_pro';
  final String _baseUrl = 'https://hsevn.com.vn';
  String? _sessionId;
  int? _userId;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/web/session/authenticate');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {'db': _database, 'login': email, 'password': password},
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) {
        _userId = data['result']['uid'];
        final String rawCookie = response.headers['set-cookie'] ?? '';
        if (rawCookie.contains('session_id')) {
          _sessionId = rawCookie.split(';')[0].split('=')[1];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_id', _sessionId!);
          await prefs.setInt('user_id', _userId!);
        }
        return data['result'];
      } else {
        throw Exception(
            data['error']['data']['message'] ?? 'Đăng nhập thất bại');
      }
    } else {
      throw Exception('Lỗi kết nối đến server: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');
    _userId = prefs.getInt('user_id');

    if (_sessionId == null || _userId == null) {
      throw Exception('Người dùng chưa đăng nhập hoặc phiên đã hết hạn.');
    }

    final url = Uri.parse('$_baseUrl/web/dataset/search_read');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'model': 'project.task',
        'domain': [
          ['user_ids', 'in', _userId]
        ],
        'fields': [
          'name',
          'project_id',
          'partner_id',
          'date_deadline',
          'stage_id'
        ],
        'limit': 80,
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'session_id=$_sessionId',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) {
        return data['result']['records'];
      } else {
        throw Exception(
            data['error']['data']['message'] ?? 'Không thể tải công việc.');
      }
    } else {
      throw Exception('Lỗi server khi tải công việc: ${response.statusCode}');
    }
  }

  // HÀM MỚI 1: Lấy tất cả các trạng thái công việc có thể có
  Future<List<dynamic>> fetchTaskStages() async {
    if (_sessionId == null) throw Exception('Chưa đăng nhập.');

    final url = Uri.parse('$_baseUrl/web/dataset/search_read');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'model': 'project.task.type', // Model chứa các trạng thái
        'domain': [], // Lấy tất cả
        'fields': ['name'], // Chỉ cần lấy tên
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'session_id=$_sessionId'
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) {
        return data['result']['records'];
      } else {
        throw Exception('Không thể tải danh sách trạng thái.');
      }
    } else {
      throw Exception('Lỗi server khi tải trạng thái.');
    }
  }

  // HÀM MỚI 2: Cập nhật trạng thái cho một công việc cụ thể
  Future<bool> updateTaskStage(int taskId, int stageId) async {
    if (_sessionId == null) throw Exception('Chưa đăng nhập.');

    final url = Uri.parse('$_baseUrl/web/dataset/call_kw/project.task/write');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'args': [
          [taskId], // Danh sách ID của các record cần cập nhật (ở đây chỉ có 1)
          {'stage_id': stageId}, // Dữ liệu cần thay đổi
        ],
        'model': 'project.task',
        'method': 'write',
        'kwargs': {},
      },
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'session_id=$_sessionId'
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result') && data['result'] == true) {
        return true; // Trả về true nếu thành công
      } else {
        throw Exception(
            data['error']['data']['message'] ?? 'Cập nhật thất bại.');
      }
    } else {
      throw Exception('Lỗi server khi cập nhật trạng thái.');
    }
  }
}

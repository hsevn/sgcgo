import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OdooApiService {
  static final OdooApiService _instance = OdooApiService._internal();
  factory OdooApiService() => _instance;
  OdooApiService._internal();

  final String _database = 'sgco128';
  final String _baseUrl = 'https://erp.sgc.com.vn';
  String? _sessionId;
  int? _userId;

  int? getCurrentUserId() => _userId;

  Future<void> _ensureSession() async {
    if (_sessionId == null || _userId == null) {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('session_id');
      _userId = prefs.getInt('user_id');
      if (_sessionId == null || _userId == null) {
        throw Exception('Người dùng chưa đăng nhập hoặc phiên đã hết hạn.');
      }
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/web/session/authenticate');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {'db': _database, 'login': email, 'password': password},
    });

    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);

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
            data['error']?['data']?['message'] ?? 'Đăng nhập thất bại');
      }
    } else {
      throw Exception('Lỗi kết nối đến server: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchTasks() async {
    await _ensureSession();
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

    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) return data['result']['records'];
      throw Exception(
          data['error']?['data']?['message'] ?? 'Không thể tải công việc.');
    }
    throw Exception('Lỗi server khi tải công việc: ${response.statusCode}');
  }

  Future<List<dynamic>> fetchTaskStages() async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/web/dataset/search_read');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'model': 'project.task.type',
        'domain': [],
        'fields': ['name']
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) return data['result']['records'];
      throw Exception('Không thể tải danh sách trạng thái.');
    }
    throw Exception('Lỗi server khi tải trạng thái.');
  }

  Future<bool> updateTaskStage(int taskId, int stageId) async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/web/dataset/call_kw/project.task/write');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'args': [
          [taskId],
          {'stage_id': stageId}
        ],
        'model': 'project.task',
        'method': 'write',
        'kwargs': {}
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result') && data['result'] == true) return true;
      throw Exception(
          data['error']?['data']?['message'] ?? 'Cập nhật thất bại.');
    }
    throw Exception('Lỗi server khi cập nhật trạng thái.');
  }

  Future<int?> getStageIdByName(String stageName) async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/web/dataset/search_read');
    final body = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'model': 'project.task.type',
        'domain': [
          ['name', '=', stageName]
        ],
        'fields': ['id'],
        'limit': 1
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['records'].isNotEmpty) {
        return data['result']['records'][0]['id'];
      }
      return null;
    }
    throw Exception('Lỗi server khi tìm stage ID.');
  }

  Future<int> createMeasurementRecord(
      Map<String, dynamic> data, List<Map<String, dynamic>> pointsData) async {
    await _ensureSession();
    data['x_measurement_point_ids'] =
        pointsData.map((point) => [0, 0, point]).toList();
    final url = Uri.parse(
        '$_baseUrl/web/dataset/call_kw/x_hse_measurement_record/create');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'args': [data],
        'model': 'x_hse_measurement_record',
        'method': 'create',
        'kwargs': {}
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      if (resData.containsKey('result')) return resData['result'];
      throw Exception(
          resData['error']?['data']?['message'] ?? 'Tạo biên bản thất bại.');
    }
    throw Exception('Lỗi server khi tạo biên bản.');
  }

  Future<Map<String, dynamic>?> fetchMeasurementRecord(int taskId) async {
    await _ensureSession();
    final searchUrl = Uri.parse('$_baseUrl/web/dataset/search_read');
    final searchBody = json.encode({
      'jsonrpc': '2.0',
      'params': {
        'model': 'x_hse_measurement_record',
        'domain': [
          ['x_task_id', '=', taskId]
        ],
        'fields': ['id'],
        'limit': 1
      }
    });
    final searchResponse = await http.post(searchUrl,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: searchBody);
    if (searchResponse.statusCode != 200)
      throw Exception('Lỗi server khi tìm biên bản.');
    final searchData = json.decode(searchResponse.body);
    if (!searchData.containsKey('result') ||
        searchData['result']['records'].isEmpty) return null;

    final recordId = searchData['result']['records'][0]['id'];
    final readUrl = Uri.parse(
        '$_baseUrl/web/dataset/call_kw/x_hse_measurement_record/read');
    final readBody = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'args': [
          [recordId]
        ],
        'model': 'x_hse_measurement_record',
        'method': 'read',
        'kwargs': {}
      }
    });
    final readResponse = await http.post(readUrl,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: readBody);
    if (readResponse.statusCode != 200)
      throw Exception('Lỗi server khi đọc chi tiết biên bản.');
    final readData = json.decode(readResponse.body);
    if (readData.containsKey('result') && readData['result'].isNotEmpty) {
      final record = readData['result'][0];
      final pointIds = record['x_measurement_point_ids'];
      if (pointIds is List && pointIds.isNotEmpty) {
        final pointsData =
            await _readNestedRecords('x_hse_measurement_point', pointIds);
        for (var point in pointsData) {
          final indicatorIds = point['x_indicator_ids'];
          if (indicatorIds is List && indicatorIds.isNotEmpty) {
            point['x_indicator_ids'] = await _readNestedRecords(
                'x_hse_measurement_indicator', indicatorIds);
          }
        }
        record['x_measurement_point_ids'] = pointsData;
      }
      return record;
    }
    return null;
  }

  Future<List<dynamic>> fetchChannels() async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/mail/init_messaging');
    final body =
        json.encode({'jsonrpc': '2.0', 'method': 'call', 'params': {}});
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['channels'] != null)
        return data['result']['channels'];
      throw Exception(data['error']?['data']?['message'] ??
          'Không thể tải danh sách hội thoại.');
    }
    throw Exception('Lỗi server khi tải hội thoại: ${response.statusCode}');
  }

  Future<List<dynamic>> fetchMessages(
      {required int channelId, int limit = 30}) async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/mail/channel/messages');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {'channel_id': channelId, 'limit': limit}
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['messages'] != null)
        return List<dynamic>.from(data['result']['messages'].reversed);
      throw Exception(
          data['error']?['data']?['message'] ?? 'Không thể tải tin nhắn.');
    }
    throw Exception('Lỗi server khi tải tin nhắn: ${response.statusCode}');
  }

  Future<void> postMessage(
      {required int channelId, required String message}) async {
    await _ensureSession();
    final url = Uri.parse('$_baseUrl/mail/message/post');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'thread_model': 'mail.channel',
        'thread_id': channelId,
        'post_data': {
          'body': message,
          'message_type': 'comment',
          'subtype_xmlid': 'mail.mt_comment'
        }
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode != 200)
      throw Exception('Lỗi server khi gửi tin nhắn: ${response.statusCode}');
    final data = json.decode(response.body);
    if (data.containsKey('error'))
      throw Exception(
          data['error']?['data']?['message'] ?? 'Gửi tin nhắn thất bại.');
  }

  Future<List<dynamic>> _readNestedRecords(
      String model, List<dynamic> ids) async {
    final url = Uri.parse('$_baseUrl/web/dataset/call_kw/$model/read');
    final body = json.encode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'args': [ids],
        'model': model,
        'method': 'read',
        'kwargs': {}
      }
    });
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_id=$_sessionId'
        },
        body: body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('result')) return data['result'];
    }
    return [];
  }
}

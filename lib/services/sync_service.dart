import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/job_measurement.dart';
import 'package:http/http.dart' as http;

class SyncService {
  static void init() {
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        _syncAll();
      }
    });
  }

  static Future<void> _syncAll() async {
    var box = Hive.box<JobMeasurement>('measurementsBox');
    for (var i = 0; i < box.length; i++) {
      var rec = box.getAt(i)!;
      if (!rec.isInHive && rec.latitude != null) { // Bạn có thể dùng field isSynced nếu muốn
        var json = rec.toMap();
        var res = await http.post(
          Uri.parse('http://<YOUR_BACKEND>/api/save_record'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(json),
        );
        if (res.statusCode == 200) {
          rec.delete(); // Xóa bản ghi sau khi đã sync thành công
        }
      }
    }
  }
}

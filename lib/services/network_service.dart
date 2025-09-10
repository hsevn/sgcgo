import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkService {
  static void listenAndSync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingRecords();
      }
    });
  }

  static void syncPendingRecords() async {
    final box = Hive.box('recordsBox');
    final unsynced =
        box.values.cast<Map>().where((e) => e['isSynced'] == false).toList();

    for (int i = 0; i < unsynced.length; i++) {
      final entry = unsynced[i];
      final response = await http.post(
        Uri.parse('http://<your-backend-ip>:5000/api/save_record'),
        body: jsonEncode(entry),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final index = box.values.toList().indexOf(entry);
        box.putAt(index, {...entry, 'isSynced': true});
      }
    }
  }
}

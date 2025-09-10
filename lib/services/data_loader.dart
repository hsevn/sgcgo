import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class StandardService {
  static Future<List<Map<String, dynamic>>> loadStandards() async {
    final jsonStr = await rootBundle.loadString('lib/data/tieu_chuan.json');
    final List data = json.decode(jsonStr);
    return List<Map<String, dynamic>>.from(data);
  }

  static List<Map<String, dynamic>> filterByCap3(
    List<Map<String, dynamic>> standards,
    String cap3,
  ) {
    return standards.where((e) => e['l3Code'] == cap3).toList();
  }
}

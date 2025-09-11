import 'dart:convert';
import 'package:flutter/services.dart';

// Enum để biểu diễn trạng thái so sánh
enum ComparisonStatus { normal, exceeded, unknown }

class StandardService {
  Map<String, dynamic> _standards = {};

  Future<void> loadStandards() async {
    try {
      final String response =
          await rootBundle.loadString('assets/tieu_chuan.json');
      _standards = json.decode(response);
    } catch (e) {
      print("Lỗi khi tải tieu_chuan.json: $e");
    }
  }

  /// So sánh giá trị đo với tiêu chuẩn
  ComparisonStatus checkValue(String indicatorName, String value) {
    if (_standards.isEmpty || !_standards.containsKey(indicatorName)) {
      return ComparisonStatus.unknown;
    }

    final double? standardValue =
        double.tryParse(_standards[indicatorName]['max_value'].toString());
    final double? currentValue = double.tryParse(value.replaceAll(',', '.'));

    if (standardValue == null || currentValue == null) {
      return ComparisonStatus.unknown;
    }

    if (currentValue > standardValue) {
      return ComparisonStatus.exceeded;
    }

    return ComparisonStatus.normal;
  }
}

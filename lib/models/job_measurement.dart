import 'package:hive/hive.dart';

part 'job_measurement.g.dart';

@HiveType(typeId: 0)
class JobMeasurement extends HiveObject {
  @HiveField(0)
  String? companyId;

  @HiveField(1)
  String? areaName;

  @HiveField(2)
  String? postureNote;

  @HiveField(3)
  Map<String, String>? indicatorValues;
}

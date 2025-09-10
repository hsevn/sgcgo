import 'package:hive/hive.dart';

part 'job_measurement.g.dart';

@HiveType(typeId: 0)
class JobMeasurement extends HiveObject {
  @HiveField(0)
  String? companyId;

  @HiveField(1)
  String? areaName;

  @HiveField(2)
  String? l1;

  @HiveField(3)
  String? l2;

  @HiveField(4)
  String? l3;

  @HiveField(5)
  String? owasPhotoPath;

  @HiveField(6)
  String? postureNote;

  @HiveField(7)
  Map<String, String>? indicatorValues;
}

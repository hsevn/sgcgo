import 'package:hive/hive.dart';

part 'job_measurement.g.dart';

@HiveType(typeId: 0)
class JobMeasurement extends HiveObject {
  @HiveField(0)
  String companyId;

  @HiveField(1)
  String locationL1;

  @HiveField(2)
  String locationL2;

  @HiveField(3)
  String locationL3;

  @HiveField(4)
  double light;

  @HiveField(5)
  double temperature;

  @HiveField(6)
  double humidity;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  double? latitude;

  @HiveField(9)
  double? longitude;

  @HiveField(10)
  DateTime timestamp;

  JobMeasurement({
    required this.companyId,
    required this.locationL1,
    required this.locationL2,
    required this.locationL3,
    required this.light,
    required this.temperature,
    required this.humidity,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });
}

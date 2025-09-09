import 'package:hive/hive.dart';

part 'job_measurement.g.dart';

@HiveType(typeId: 0)
class JobMeasurement extends HiveObject {
  @HiveField(0)
  String companyId;

  @HiveField(1)
  String? locationL1;

  @HiveField(2)
  String? locationL2;

  @HiveField(3)
  String? locationL3;

  @HiveField(4)
  double? light;

  @HiveField(5)
  double? temperature;

  @HiveField(6)
  double? humidity;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  double? latitude;

  @HiveField(9)
  double? longitude;

  @HiveField(10)
  DateTime? timestamp;

  @HiveField(11)
  bool isInHive;

  @HiveField(12)
  String? description;

  JobMeasurement({
    required this.companyId,
    this.locationL1,
    this.locationL2,
    this.locationL3,
    this.light,
    this.temperature,
    this.humidity,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.isInHive = true,
    this.description,
  });
}

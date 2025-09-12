import 'package:hive/hive.dart';
import 'package:sgcgo/services/gps_service.dart';

part 'activity_log_service.g.dart'; // <--- DÒNG BỊ THIẾU LÀ DÒNG NÀY

@HiveType(typeId: 1) // ID phải khác với JobMeasurement (typeId: 0)
class ActivityLog extends HiveObject {
  @HiveField(0)
  late String action;

  @HiveField(1)
  late DateTime timestamp;

  @HiveField(2)
  double? latitude;

  @HiveField(3)
  double? longitude;
}

class ActivityLogService {
  final GpsService _gpsService;
  late final Box<ActivityLog> _logBox;

  ActivityLogService(this._gpsService);

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(ActivityLogAdapter().typeId)) {
      Hive.registerAdapter(ActivityLogAdapter());
    }
    _logBox = await Hive.openBox<ActivityLog>('activity_logs');
  }

  Future<void> logAction(String action) async {
    final position = await _gpsService.getCurrentPosition();

    final log = ActivityLog()
      ..action = action
      ..timestamp = DateTime.now()
      ..latitude = position?.latitude
      ..longitude = position?.longitude;

    await _logBox.add(log);
    print(
        "LOGGED: ${log.action} at ${log.timestamp} with GPS: (${log.latitude}, ${log.longitude})");
  }
}

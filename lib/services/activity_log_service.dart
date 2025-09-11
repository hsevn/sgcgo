import 'package:hive/hive.dart';
import 'package:sgcgo/services/gps_service.dart'; // Giả sử GpsService nằm ở đây

// Cần tạo adapter cho class này
// Chạy lệnh: flutter pub run build_runner build --delete-conflicting-outputs
@HiveType(typeId: 1) // ID phải khác với JobMeasurement
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
    // Đăng ký adapter
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
    print("LOGGED: ${log.action} at ${log.timestamp}");
  }
}

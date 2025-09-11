import 'package:geolocator/geolocator.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

// Lớp để lưu trữ tọa độ đã chuyển đổi
class Vn2000Coordinates {
  final double x;
  final double y;
  Vn2000Coordinates(this.x, this.y);

  @override
  String toString() =>
      'VN2000(X: ${x.toStringAsFixed(3)}, Y: ${y.toStringAsFixed(3)})';
}

class GpsService {
  late proj4.Projection _wgs84;
  late proj4.Projection _vn2000;

  GpsService() {
    // Định nghĩa 2 hệ tọa độ
    _wgs84 = proj4.Projection.get('EPSG:4326')!; // Hệ tọa độ GPS chuẩn

    // Định nghĩa VN-2000 cho kinh tuyến trục 105.75 (phổ biến ở miền Nam)
    // Lưu ý: Tùy vào khu vực tỉnh thành mà kinh tuyến trục có thể thay đổi
    _vn2000 = proj4.Projection.add(
      'VN-2000/TM-3_105-75',
      '+proj=tmerc +lat_0=0 +lon_0=105.75 +k=0.9999 +x_0=500000 +y_0=0 +ellps=WGS84 +towgs84=-191.90441429,-39.30318279,-111.45032835,0.00928836,0.01975479,-0.00427372,0.252906278 +units=m +no_defs',
    );
  }

  /// Yêu cầu và kiểm tra quyền truy cập vị trí
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Dịch vụ vị trí bị tắt, không thể tiếp tục
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Người dùng từ chối quyền
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Người dùng từ chối vĩnh viễn
      return false;
    }

    return true;
  }

  /// Lấy vị trí hiện tại (dạng WGS-84)
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Lỗi khi lấy vị trí GPS: $e");
      return null;
    }
  }

  /// Chuyển đổi từ WGS-84 sang VN-2000
  Vn2000Coordinates? convertToVn2000(Position? position) {
    if (position == null) return null;

    final point = proj4.Point(x: position.longitude, y: position.latitude);
    final result = _wgs84.transform(_vn2000, point);

    return Vn2000Coordinates(result.x, result.y);
  }
}

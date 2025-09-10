import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/job_measurement.dart';
import 'screens/record_list_screen.dart';

// Chỉ giữ lại MỘT hàm main duy nhất
Future<void> main() async {
  // Đảm bảo các thành phần của Flutter đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive
  await Hive.initFlutter();

  // Đăng ký Adapter cho class của bạn
  Hive.registerAdapter(JobMeasurementAdapter());

  // Thử mở box, nếu có lỗi (do dữ liệu cũ không tương thích) thì xóa đi và tạo lại
  try {
    await Hive.openBox<JobMeasurement>('measurements');
  } catch (e) {
    await Hive.deleteBoxFromDisk('measurements');
    await Hive.openBox<JobMeasurement>('measurements');
  }

  // Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quan Trắc Môi Trường',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      // Dữ liệu này có thể được truyền từ màn hình đăng nhập hoặc màn hình chính sau này
      home: const RecordListScreen(
        companyName: 'Công ty ABC',
        companyAddress: '123 Đường XYZ',
      ),
    );
  }
}

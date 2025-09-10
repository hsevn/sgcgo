import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/job_measurement.dart';
import 'screens/record_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(JobMeasurementAdapter());
  await Hive.openBox<JobMeasurement>('measurements');

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
      home: const RecordListScreen(
        companyName: 'Công ty ABC',
        companyAddress: '123 Đường XYZ',
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(JobMeasurementAdapter());

  try {
    await Hive.openBox<JobMeasurement>('measurements');
  } catch (e) {
    // Nếu lỗi đọc dữ liệu cũ -> xoá box và mở lại
    await Hive.deleteBoxFromDisk('measurements');
    await Hive.openBox<JobMeasurement>('measurements');
  }

  runApp(const MyApp());
}

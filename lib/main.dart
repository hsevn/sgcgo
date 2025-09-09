import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/job_measurement.dart';
import 'screens/record_list_screen.dart';

void main() async {
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
      title: 'SGC Go',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecordListScreen(
        companyName: 'Công ty ABC',
        companyAddress: 'KCN Long Giang',
      ),
    );
  }
}

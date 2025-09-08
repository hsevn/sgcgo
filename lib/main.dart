import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/record_list_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

Stream<ConnectivityResult> networkStream = Connectivity().onConnectivityChanged;
networkStream.listen((status) {
if (status != ConnectivityResult.none) {
syncRecords();
}
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('recordsBox');
  runApp(const SgcGoApp());
}

class SgcGoApp extends StatelessWidget {
  const SgcGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGC‑go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF9F2F7),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/tasks': (context) => const TaskListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/records') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RecordListScreen(companyId: args['companyId']),
          );
        }
        return null;
      },
    );
  }
}

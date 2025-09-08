import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/task_list_screen.dart'; // 👈 đúng chỗ duy nhất chứa TaskListScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGC-go',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => DashboardScreen(), // bỏ const nếu là StatefulWidget
        '/tasks': (context) => const TaskListScreen(),
      },
    );
  }
}

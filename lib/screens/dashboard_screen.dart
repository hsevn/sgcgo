import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.work_outline, 'label': 'Công việc', 'route': '/tasks'},
      {'icon': Icons.edit_note, 'label': 'Biên bản', 'route': '/records'},
      {'icon': Icons.sync, 'label': 'Đồng bộ', 'route': '/sync'},
      {'icon': Icons.settings, 'label': 'Cài đặt', 'route': '/settings'},
      {'icon': Icons.logout, 'label': 'Đăng xuất', 'route': '/'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = features[index];
            return GestureDetector(
              onTap: () {
                final route = item['route'] as String;
                if (route == '/') {
                  Navigator.pushReplacementNamed(context, '/');
                } else {
                  Navigator.pushNamed(context, route);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, size: 40, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

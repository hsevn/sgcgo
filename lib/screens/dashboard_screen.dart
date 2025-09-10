import 'package:flutter/material.dart';
import 'task_list_screen.dart'; // Thêm import này
import '../login_screen.dart'; // Thêm import này

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu các nút chức năng
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
        automaticallyImplyLeading: false, // Ẩn nút back
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

                // --- LOGIC ĐIỀU HƯỚNG ĐÃ ĐƯỢC SỬA ---
                if (route == '/tasks') {
                  // Khi nhấn "Công việc", chuyển đến TaskListScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TaskListScreen()),
                  );
                } else if (route == '/') {
                  // Khi nhấn "Đăng xuất", quay về LoginScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                } else {
                  // Các nút khác chưa có chức năng, có thể hiển thị thông báo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Chức năng "${item['label']}" đang được phát triển.')),
                  );
                }
                // ------------------------------------
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
                    Icon(item['icon'] as IconData,
                        size: 40, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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

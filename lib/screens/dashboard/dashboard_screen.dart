// File: lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
// Đảm bảo đường dẫn này đúng với vị trí file TaskListScreen của bạn
import '../tasks/task_list_screen.dart';
// Đảm bảo đường dẫn này đúng với vị trí file LoginScreen của bạn
import '../login/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu cho các mục trên Dashboard của bạn
    final features = [
      {
        'icon': Icons.assignment_late_outlined,
        'label': 'BB QTMT LĐ',
        'route': '/tasks' // Sẽ điều hướng đến TaskListScreen
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'BB QTMT',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.science_outlined,
        'label': 'BB PT PTN',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.monetization_on_outlined,
        'label': 'Chi Phí',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.sync_alt_outlined,
        'label': 'Hoàn Ứng',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.history_outlined,
        'label': 'Lịch Sử CV',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.water_drop_outlined,
        'label': 'Mẫu nước',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.air_outlined,
        'label': 'Mẫu khí',
        'route': '/not_implemented'
      },
      {
        'icon': Icons.code_outlined,
        'label': 'HDSD TB',
        'route': '/not_implemented'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE9F5F9), // Màu nền tổng thể
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Không có đổ bóng
        flexibleSpace: Container(
          // Thiết kế custom cho AppBar với bo tròn dưới
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: const Center(
            child: Text(
              'Nội dung công việc', // Tiêu đề AppBar
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
        ),
        automaticallyImplyLeading: false, // Không hiển thị nút back mặc định
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          itemCount: features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 cột
            childAspectRatio: 0.9, // Tỷ lệ khung hình của mỗi ô
            crossAxisSpacing: 16, // Khoảng cách ngang
            mainAxisSpacing: 16, // Khoảng cách dọc
          ),
          itemBuilder: (context, index) {
            final item = features[index];
            return _buildDashboardItem(
              context: context,
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              route: item['route'] as String,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nút chat
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Colors.blueAccent, size: 30),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Chức năng Chat đang được phát triển.')),
                );
              },
            ),
            // Nút đăng xuất
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 30),
              onPressed: () {
                // Điều hướng về màn hình đăng nhập và xóa tất cả các màn hình trước đó khỏi stack
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget riêng để xây dựng mỗi ô item trên Dashboard
  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        if (route == '/tasks') {
          // Điều hướng đến TaskListScreen
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const TaskListScreen()));
        } else if (route == '/login') {
          // Trường hợp này là để test hoặc nếu có route riêng cho login
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else {
          // Hiển thị thông báo nếu chức năng chưa được triển khai
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Chức năng "$label" đang được phát triển.')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Hiệu ứng đổ bóng nhẹ
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF3F51B5)), // Icon
            const SizedBox(height: 12),
            Text(label, // Tên chức năng
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'task_list_screen.dart';
import 'login_screen.dart'; // Corrected path

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data for the dashboard items
    final features = [
      {
        'icon': Icons.assignment_late_outlined,
        'label': 'BB QTMT LĐ',
        'route': '/tasks'
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
      backgroundColor: const Color(0xFFE9F5F9),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: const Center(
            child: Text(
              'Nội dung công việc',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          itemCount: features.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Colors.blueAccent, size: 30),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 30),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        if (route == '/tasks') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const TaskListScreen()));
        } else if (route == '/') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else {
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF3F51B5)),
            const SizedBox(height: 12),
            Text(label,
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

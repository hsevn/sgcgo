import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.assignment_turned_in,
        'label': 'BB QTMT LD',
        'route': '/tasks',
      },
      {
        'icon': Icons.library_books,
        'label': 'BB QTMT',
        'route': null,
      },
      {
        'icon': Icons.fact_check,
        'label': 'BP PT PTN',
        'route': null,
      },
      {
        'icon': Icons.attach_money,
        'label': 'Chi Phí',
        'route': null,
      },
      {
        'icon': Icons.repeat,
        'label': 'Hoàn Ứng',
        'route': null,
      },
      {
        'icon': Icons.history,
        'label': 'Lịch Sử CV',
        'route': null,
      },
      {
        'icon': Icons.water_drop,
        'label': 'Mẫu nước',
        'route': null,
      },
      {
        'icon': Icons.air,
        'label': 'Mẫu khí',
        'route': null,
      },
      {
        'icon': Icons.qr_code,
        'label': 'HDSD TB',
        'route': null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nội dung công việc',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 60),
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () {
                    final route = item['route'] as String?;
                    if (route != null) {
                      Navigator.pushNamed(context, route);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng chưa hoạt động')),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 36,
                          color: Colors.blue, // màu xanh dương chủ đạo
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Nút Logout & Message ở dưới cùng
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: IconButton(
                icon: const Icon(Icons.message, color: Colors.blue, size: 32),
                onPressed: () {
                  // TODO: tin nhắn odoo
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có muốn thoát không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // đóng dialog
              Navigator.pushReplacementNamed(context, '/'); // quay lại login
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }
}

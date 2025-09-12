// File: lib/screens/tasks/task_list_screen.dart

import 'package:flutter/material.dart';
// Đảm bảo đường dẫn này đúng với vị trí file RecordListScreen của bạn
import '../records/record_list_screen.dart';
// Đảm bảo đường dẫn này đúng với vị trí file OdooApiService của bạn
import '../../services/odoo_api_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // Controller cho ô tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // Biến để lưu trữ chuỗi tìm kiếm
  String _filterStatus = 'Tất cả'; // Biến để lưu trữ trạng thái lọc
  bool _showSearch = false; // Biến để ẩn/hiện ô tìm kiếm

  final OdooApiService _apiService = OdooApiService(); // Service gọi API Odoo
  Future<List<dynamic>>? _tasksFuture; // Future để tải dữ liệu công việc
  List<dynamic> _allTasks = []; // Danh sách tất cả công việc từ Odoo

  @override
  void initState() {
    super.initState();
    _fetchTasks(); // Gọi hàm tải công việc khi khởi tạo màn hình
  }

  // Hàm tải danh sách công việc từ Odoo
  Future<void> _fetchTasks() async {
    setState(() {
      _tasksFuture = _apiService.getTasks().then((data) {
        _allTasks = data; // Lưu dữ liệu gốc
        return data;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách công việc dựa trên tìm kiếm và trạng thái
    final filteredTasks = _allTasks.where((task) {
      final taskName = (task['name'] ?? '').toLowerCase();
      final projectName =
          (task['project_id'] is List ? task['project_id'][1] : '')
              .toLowerCase();
      final partnerName =
          (task['partner_id'] is List ? task['partner_id'][1] : '')
              .toLowerCase();

      final matchesSearch = taskName.contains(_searchQuery.toLowerCase()) ||
          projectName.contains(_searchQuery.toLowerCase()) ||
          partnerName.contains(_searchQuery.toLowerCase());

      // TODO: Odoo API không trả về 'status' mặc định như dữ liệu giả của bạn.
      // Bạn cần xác định trường nào trong Odoo tương ứng với trạng thái công việc
      // và cập nhật logic lọc trạng thái ở đây.
      // Ví dụ: Odoo có thể có trường 'stage_id' hoặc 'kanban_state'.
      // Giả định tạm thời là không lọc theo trạng thái nếu không có trường tương ứng.
      final matchesStatus = _filterStatus ==
          'Tất cả'; // Tạm thời bỏ qua lọc trạng thái cho đến khi có trường Odoo
      // Hoặc nếu bạn có trường status trong Odoo, hãy thay thế:
      // final taskStatus = (task['x_task_status'] ?? '').toString(); // Giả định trường x_task_status
      // final matchesStatus = _filterStatus == 'Tất cả' || taskStatus == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context), // Quay về màn hình trước (Dashboard)
        ),
        actions: [
          // Nút tìm kiếm
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(
                () => _showSearch = !_showSearch), // Bật/tắt ô tìm kiếm
          ),
          // Nút làm mới dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks, // Tải lại danh sách công việc
          ),
        ],
      ),
      body: Column(
        children: [
          // Ô tìm kiếm (hiện khi _showSearch là true)
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Tìm kiếm theo tên công việc, dự án hoặc khách hàng...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(
                    () => _searchQuery = val), // Cập nhật chuỗi tìm kiếm
              ),
            ),
          // Các nút lọc trạng thái (giữ nguyên giao diện của bạn)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children:
                  ['Tất cả', 'Tạm hoãn', 'Đang làm', 'Hoàn thành'].map((label) {
                final isSelected = _filterStatus == label;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.blue : Colors.grey.shade300,
                      elevation: isSelected ? 2 : 0,
                    ),
                    onPressed: () => setState(() => _filterStatus = label),
                    child: Text(label,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black)),
                  ),
                );
              }).toList(),
            ),
          ),
          // Hàng tiêu đề của bảng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: const [
                Expanded(
                    flex: 2,
                    child: Text('Tên Cty',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text(
                        'Dự án', // Thay "Địa chỉ" bằng "Dự án" cho phù hợp Odoo
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Khách hàng', // Thay "Bản đồ" bằng "Khách hàng"
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text(
                        'Ngày deadline', // Thay "Ngày QT" bằng "Ngày deadline"
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Trạng thái',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Danh sách công việc (sử dụng FutureBuilder để hiển thị dữ liệu từ Odoo)
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có công việc nào.'));
                } else {
                  // Dữ liệu đã tải thành công, hiển thị filteredTasks
                  return ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      // Lấy tên dự án và khách hàng từ Odoo (dữ liệu dạng List [id, name])
                      final projectName = task['project_id'] is List
                          ? task['project_id'][1]
                          : 'N/A';
                      final partnerName = task['partner_id'] is List
                          ? task['partner_id'][1]
                          : 'N/A';
                      final dateDeadline = task['date_deadline'] ?? 'N/A';

                      // TODO: Xác định cách lấy trạng thái từ Odoo
                      // Giả định có một trường 'x_task_status' hoặc 'stage_id'
                      final taskStatus = task['stage_id'] is List
                          ? task['stage_id'][1]
                          : 'Mới'; // Ví dụ: Lấy stage_id
                      Color statusColor = Colors.grey;
                      if (taskStatus == 'Mới') {
                        statusColor = Colors.blue;
                      } else if (taskStatus == 'Đang tiến hành') {
                        // Tên stage trong Odoo
                        statusColor = Colors.orange;
                      } else if (taskStatus == 'Hoàn thành') {
                        // Tên stage trong Odoo
                        statusColor = Colors.green;
                      }
                      // Cập nhật các màu sắc và trạng thái dựa trên tên stage thực tế của Odoo

                      return InkWell(
                        onTap: () {
                          // Điều hướng đến màn hình chi tiết biên bản
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordListScreen(
                                companyName: task['name'] ?? 'Không tên',
                                companyAddress:
                                    projectName, // Sử dụng tên dự án thay địa chỉ
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2, child: Text(task['name'] ?? 'N/A')),
                              Expanded(flex: 2, child: Text(projectName)),
                              Expanded(
                                  flex: 1,
                                  child:
                                      Text(partnerName)), // Hiển thị khách hàng
                              Expanded(flex: 2, child: Text(dateDeadline)),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    taskStatus,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          // Bottom bar
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Chức năng Tin nhắn đang được phát triển.')),
                      );
                    },
                    icon: const Icon(Icons.message,
                        color: Colors.blue, size: 32)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context), // Quay về Dashboard
                  icon: const Icon(Icons.home, color: Colors.blue, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

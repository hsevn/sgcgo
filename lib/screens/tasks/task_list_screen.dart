import 'package:flutter/material.dart';
import '../../services/odoo_api_service.dart';
import '../records/record_list_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  // --- BIẾN TRẠNG THÁI ---
  final TextEditingController _searchController = TextEditingController();
  final OdooApiService _apiService = OdooApiService();

  List<dynamic> _allTasks = [];
  List<dynamic> _taskStages = []; // BIẾN MỚI: Để lưu danh sách trạng thái
  String? _errorMessage;
  bool _isLoading = true;
  bool _isUpdating = false; // BIẾN MỚI: Để hiển thị loading khi cập nhật

  String _searchQuery = '';
  String _filterStatus = 'Tất cả';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Tải cả công việc và trạng thái
  }

  // --- HÀM TẢI DỮ LIỆU ---
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tải đồng thời cả công việc và danh sách trạng thái để tăng tốc độ
      final results = await Future.wait([
        _apiService.fetchTasks(),
        _apiService.fetchTaskStages(),
      ]);
      setState(() {
        _allTasks = results[0];
        _taskStages = results[1];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- HÀM MỚI: HIỂN THỊ HỘP THOẠI CHỌN TRẠNG THÁI ---
  Future<void> _showStageSelectionDialog(dynamic task) async {
    final int currentStageId = task['stage_id'][0];

    final selectedStage = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Chọn trạng thái mới'),
          children: _taskStages.map<Widget>((stage) {
            final bool isCurrent = stage['id'] == currentStageId;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, stage),
              child: Text(
                stage['name'] ?? 'Không tên',
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.blue : Colors.black,
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    // Nếu người dùng chọn một trạng thái mới
    if (selectedStage != null) {
      final int taskId = task['id'];
      final int newStageId = selectedStage['id'];

      // Không làm gì nếu chọn lại trạng thái cũ
      if (newStageId == currentStageId) return;

      setState(() => _isUpdating = true);

      try {
        final success = await _apiService.updateTaskStage(taskId, newStageId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật trạng thái thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadInitialData(); // Tải lại toàn bộ dữ liệu để làm mới
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi cập nhật: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  // --- CÁC HÀM HELPER KHÁC ---
  String _getOdooRecordName(dynamic field) {
    if (field is List && field.length >= 2) {
      return field[1].toString();
    }
    return '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _showSearch = !_showSearch)),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadInitialData),
        ],
      ),
      body: Stack(
        // Dùng Stack để hiển thị loading indicator đè lên trên
        children: [
          Column(
            children: [
              // Thanh tìm kiếm và các nút lọc (giữ nguyên)
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, dự án, khách hàng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Row(
                  children: ['Tất cả', 'Tạm hoãn', 'Đang làm', 'Hoàn thành']
                      .map((label) {
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
                                color:
                                    isSelected ? Colors.white : Colors.black)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade200,
                child: Row(
                  children: const [
                    Expanded(
                        flex: 2,
                        child: Text('Tên Cty',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Dự án',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 1,
                        child: Text('Khách hàng',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 2,
                        child: Text('Ngày deadline',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 1,
                        child: Text('Trạng thái',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
              // Bottom bar (giữ nguyên)
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Chức năng Tin nhắn đang được phát triển.')),
                            ),
                        icon: const Icon(Icons.message,
                            color: Colors.blue, size: 32)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.home, color: Colors.blue, size: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // HIỂN THỊ LOADING KHI ĐANG CẬP NHẬT
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Lỗi: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center),
      ));
    }

    // Logic lọc (giữ nguyên)
    final filteredTasks = _allTasks.where((task) {
      final taskName = (task['name'] ?? '').toLowerCase();
      final projectName = _getOdooRecordName(task['project_id']).toLowerCase();
      final partnerName = _getOdooRecordName(task['partner_id']).toLowerCase();

      final matchesSearch = taskName.contains(_searchQuery.toLowerCase()) ||
          projectName.contains(_searchQuery.toLowerCase()) ||
          partnerName.contains(_searchQuery.toLowerCase());

      final stageName = _getOdooRecordName(task['stage_id']);
      bool matchesStatus = false;
      if (_filterStatus == 'Tất cả') {
        matchesStatus = true;
      } else {
        switch (_filterStatus) {
          case 'Đang làm':
            matchesStatus = (stageName.toLowerCase() == 'in progress' ||
                stageName.toLowerCase() == 'đang tiến hành');
            break;
          case 'Hoàn thành':
            matchesStatus = (stageName.toLowerCase() == 'done' ||
                stageName.toLowerCase() == 'hoàn thành');
            break;
          case 'Tạm hoãn':
            matchesStatus = (stageName.toLowerCase() == 'on hold' ||
                stageName.toLowerCase() == 'tạm hoãn' ||
                stageName.toLowerCase() == 'cancelled' ||
                stageName.toLowerCase() == 'hủy');
            break;
        }
      }

      return matchesSearch && matchesStatus;
    }).toList();

    if (filteredTasks.isEmpty) {
      return const Center(child: Text('Không tìm thấy công việc nào.'));
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        // ... (lấy dữ liệu như cũ)
        final projectName = _getOdooRecordName(task['project_id']);
        final partnerName = _getOdooRecordName(task['partner_id']);
        final dateDeadline = task['date_deadline'] ?? 'N/A';
        final taskStatus = _getOdooRecordName(task['stage_id']);
        Color statusColor = Colors.grey;
        final statusLower = taskStatus.toLowerCase();
        if (statusLower.contains('progress') || statusLower.contains('đang')) {
          statusColor = Colors.orange;
        } else if (statusLower.contains('done') ||
            statusLower.contains('hoàn thành')) {
          statusColor = Colors.green;
        } else if (statusLower.contains('hold') ||
            statusLower.contains('tạm hoãn') ||
            statusLower.contains('cancel') ||
            statusLower.contains('hủy')) {
          statusColor = Colors.red;
        } else if (statusLower.contains('new') || statusLower.contains('mới')) {
          statusColor = Colors.blue;
        }

        return InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordListScreen(
                    taskId: task['id'],
                    companyName: task['name'] ?? 'Không có tên',
                    companyAddress: projectName,
                  ),
                ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Expanded(flex: 2, child: Text(task['name'] ?? 'N/A')),
                Expanded(flex: 2, child: Text(projectName)),
                Expanded(flex: 1, child: Text(partnerName)),
                Expanded(flex: 2, child: Text(dateDeadline)),
                // CẬP NHẬT Ô TRẠNG THÁI
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    // Bọc trong GestureDetector để bắt sự kiện nhấn
                    onTap: () => _showStageSelectionDialog(
                        task), // Gọi hàm hiển thị dialog
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                statusColor), // Thêm viền để trông dễ nhấn hơn
                      ),
                      child: Text(
                        taskStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}

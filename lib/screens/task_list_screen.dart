import 'package:flutter/material.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _filterStatus = 'Tất cả';
  bool _showSearch = false;

  final List<Map<String, String>> _allTasks = List.generate(20, (index) {
    final statuses = ['Đang làm', 'Tạm hoãn', 'Hoàn thành'];
    return {
      'name': 'Công ty ${index + 1}',
      'address': 'Địa chỉ ${index + 1}',
      'date': '01/09/2025',
      'status': statuses[index % statuses.length],
    };
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _allTasks.where((task) {
      final matchesSearch =
          task['name']!.toLowerCase().contains(_search.toLowerCase());
      final matchesStatus =
          _filterStatus == 'Tất cả' || task['status'] == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên công ty...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _search = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  ['Tất cả', 'Tạm hoãn', 'Đang làm', 'Hoàn thành'].map((label) {
                final isSelected = _filterStatus == label;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.grey.shade300,
                    elevation: isSelected ? 2 : 0,
                  ),
                  onPressed: () => setState(() => _filterStatus = label),
                  child: Text(
                    label,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
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
                    child: Text('Địa chỉ',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Bản đồ',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Ngày QT',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Trạng thái',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final task = filtered[index];
                Color statusColor = Colors.grey;
                if (task['status'] == 'Đang làm')
                  statusColor = Colors.orange;
                else if (task['status'] == 'Tạm hoãn')
                  statusColor = Colors.red;
                else if (task['status'] == 'Hoàn thành')
                  statusColor = Colors.green;

                return InkWell(
                  onTap: () {
                    // Điều hướng trực tiếp đến RecordListScreen và truyền dữ liệu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecordListScreen(
                          companyName: task['name']!,
                          companyAddress: task['address']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(task['name']!)),
                        Expanded(flex: 2, child: Text(task['address']!)),
                        const Expanded(
                            flex: 1,
                            child: Icon(Icons.map, color: Colors.blue)),
                        Expanded(flex: 2, child: Text(task['date']!)),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task['status']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Tin nhắn sau này
                  },
                  icon: const Icon(Icons.message, color: Colors.blue, size: 32),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
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

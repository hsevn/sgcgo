// lib/screens/record_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_selector/file_selector.dart';

import '../models/job_measurement.dart';

class RecordListScreen extends StatefulWidget {
  final String companyName;
  final String companyAddress;

  const RecordListScreen({
    Key? key,
    required this.companyName,
    required this.companyAddress,
  }) : super(key: key);

class LocationEntry {
  final String l1Code;
  final String l2Code;
  final String l3Code;
  final String description;

  LocationEntry({
    required this.l1Code,
    required this.l2Code,
    required this.l3Code,
    required this.description,
  });
}

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  late Box<JobMeasurement> box;

  @override
  void initState() {
    super.initState();
    box = Hive.box<JobMeasurement>('measurements');
    if (box.isEmpty) {
      box.add(JobMeasurement(companyId: widget.companyName));
    }
  }

  void addCard() {
    box.add(JobMeasurement(companyId: widget.companyName));
  }

  void deleteCard(JobMeasurement entry) {
    entry.delete();
  }

  void saveDraft() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu nháp')));
  }

  void submit() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu & Gửi')));
  }

  Future<void> pickImage(JobMeasurement entry) async {
    final typeGroup =
        const XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      entry.imagePath = file.path;
      entry.timestamp = DateTime.now();
      await entry.save();
      setState(() {});
    }
  }

  Widget buildOwasBox(JobMeasurement entry) {
    if (entry.imagePath != null && File(entry.imagePath!).existsSync()) {
      return GestureDetector(
        onTap: () => pickImage(entry),
        child: Image.file(
          File(entry.imagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.camera_alt),
      onPressed: () => pickImage(entry),
    );
  }

  void editValue(JobMeasurement entry, String label) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nhập $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) {
                if (label == 'Ánh sáng')
                  entry.light = v;
                else if (label == 'Nhiệt độ')
                  entry.temperature = v;
                else if (label == 'Độ ẩm') entry.humidity = v;
                entry.save();
                setState(() {});
              }
              Navigator.pop(ctx);
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Widget measBox(JobMeasurement entry, String label) {
    double? val;
    if (label == 'Ánh sáng')
      val = entry.light;
    else if (label == 'Nhiệt độ')
      val = entry.temperature;
    else if (label == 'Độ ẩm') val = entry.humidity;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(val?.toString() ?? '-'),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => editValue(entry, label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biên bản quan trắc môi trường lao động'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Công ty + địa chỉ + icon định vị
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${widget.companyName}\n${widget.companyAddress}',
                    style: titleStyle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: () {
                    // TODO: Mở Google Maps theo địa chỉ
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Danh sách điểm đo
            ValueListenableBuilder<Box<JobMeasurement>>(
              valueListenable: box.listenable(),
              builder: (context, box, _) {
                final entries = box.values.toList();
                return Column(
                  children: entries.map((entry) {
                    final idx = entries.indexOf(entry) + 1;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề điểm đo + nút thêm/xóa
                            Row(
                              children: [
                                Text(
                                  'Điểm đo $idx',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteCard(entry),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: addCard,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Vị trí và các cấp
                            TextFormField(
                              initialValue: entry.locationL1,
                              decoration: const InputDecoration(
                                  labelText: 'Vị trí (mặc định)'),
                              onChanged: (v) {
                                entry.locationL1 = v;
                                entry.save();
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: 'Cấp 1'),
                                    value: entry.locationL2,
                                    items: const [],
                                    onChanged: (v) {
                                      entry.locationL2 = v;
                                      entry.save();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: 'Cấp 2'),
                                    value: entry.locationL3,
                                    items: const [],
                                    onChanged: (v) {
                                      entry.locationL3 = v;
                                      entry.save();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: 'Cấp 3'),
                                    value: entry.locationL3,
                                    items: const [],
                                    onChanged: (v) {
                                      entry.locationL3 = v;
                                      entry.save();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Các chỉ tiêu đo
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                measBox(entry, 'Ánh sáng'),
                                measBox(entry, 'Nhiệt độ'),
                                measBox(entry, 'Độ ẩm'),
                                measBox(entry, 'VT gió'),
                                measBox(entry, 'Bụi TP'),
                                measBox(entry, 'CO'),
                                measBox(entry, 'NO2'),
                                measBox(entry, 'SO2'),
                                buildOwasBox(entry),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mô tả tư thế + nút thêm chỉ tiêu
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: entry.description,
                                    decoration: const InputDecoration(
                                        labelText: 'Mô tả tư thế lao động'),
                                    onChanged: (v) {
                                      entry.description = v;
                                      entry.save();
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    // TODO: thêm chỉ tiêu mới động
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: saveDraft,
                    child: const Text('Lưu nháp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: submit,
                    child: const Text('Lưu & Gửi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RecordListScreen extends StatefulWidget {
  final String companyId;
  const RecordListScreen({super.key, required this.companyId});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final List<RecordEntry> entries = [RecordEntry()];
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    setState(() => _currentPosition = pos);
  }

  void _addEntry() => setState(() => entries.add(RecordEntry()));
  void _removeEntry(int idx) {
    if (entries.length > 1) setState(() => entries.removeAt(idx));
  }

  Future<void> _pickImage(int idx) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => entries[idx].photoPath = image.path);
    }
  }

  Future<void> _save({required bool complete}) async {
    final firestore = FirebaseFirestore.instance;
    final companyRef = firestore.collection('companies').doc(widget.companyId).collection('records');

    for (var entry in entries) {
      final data = entry.toMap();

      data['timestamp'] = FieldValue.serverTimestamp();
      if (_currentPosition != null) {
        data['gps'] = GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude);
      }

      await companyRef.add(data);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${complete ? 'Hoàn tất' : 'Đã lưu nháp'} ${entries.length} mục')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biên bản: ${widget.companyId}'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () => _save(complete: false)),
          IconButton(icon: const Icon(Icons.check), onPressed: () => _save(complete: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addEntry, child: const Icon(Icons.add)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (context, idx) {
          return RecordCard(
            entry: entries[idx],
            onPickImage: () => _pickImage(idx),
            onDelete: () => _removeEntry(idx),
          );
        },
      ),
    );
  }
}

class RecordEntry {
  String? area, location, detail, address, inspector, weather, photoPath;
  DateTime? date;
  TimeOfDay? timeIn, timeOut;
  double? temp, humidity, light, windSpeed, noise, vibration, co2, o2, co, electricField, radiation;

  Map<String, dynamic> toMap() => {
    'area': area,
    'location': location,
    'detail': detail,
    'address': address,
    'date': date?.toIso8601String(),
    'timeIn': timeIn?.formatTimeOfDay(),
    'timeOut': timeOut?.formatTimeOfDay(),
    'inspector': inspector,
    'weather': weather,
    'temp': temp,
    'humidity': humidity,
    'light': light,
    'windSpeed': windSpeed,
    'noise': noise,
    'vibration': vibration,
    'co2': co2,
    'o2': o2,
    'co': co,
    'electricField': electricField,
    'radiation': radiation,
    'photoPath': photoPath,
  };
}

class RecordCard extends StatefulWidget {
  final RecordEntry entry;
  final VoidCallback onPickImage;
  final VoidCallback onDelete;

  const RecordCard({
    super.key,
    required this.entry,
    required this.onPickImage,
    required this.onDelete,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

extension on TimeOfDay {
  String formatTimeOfDay() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _RecordCardState extends State<RecordCard> {
  final areas = ['Xưởng ống thẳng', 'Xưởng ống tròn']; // ví dụ
  final locations = {
    'Xưởng ống thẳng': ['Khu vực công cộng', 'Khu vực chỉnh thẳng'],
    'Xưởng ống tròn': ['Khu vực A', 'Khu vực B'],
  };
  final details = {
    'Khu vực công cộng': ['5.9.5 Phòng tắm trị liệu'],
    'Khu vực chỉnh thẳng': ['2.1 Công đoạn...'],
  };

  final tempCtrl = TextEditingController();
  final humidCtrl = TextEditingController();
  final inspectorCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final weatherCtrl = TextEditingController();

  @override
  void dispose() {
    tempCtrl.dispose();
    humidCtrl.dispose();
    inspectorCtrl.dispose();
    addressCtrl.dispose();
    weatherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final locList = entry.area != null ? locations[entry.area!] ?? [] : <String>[];
    final detailList = entry.location != null ? details[entry.location!] ?? [] : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Dropdowns
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cấp 1 (Khu vực)'),
              value: entry.area,
              items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() {
                entry.area = v;
                entry.location = null;
                entry.detail = null;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cấp 2 (Vị trí)'),
              value: entry.location,
              items: locList.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() {
                entry.location = v;
                entry.detail = null;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Cấp 3 (Chi tiết)'),
              value: entry.detail,
              items: detailList.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => entry.detail = v),
            ),
            const Divider(height: 20),
            TextFormField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Địa chỉ'),
              onChanged: (v) => entry.address = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: inspectorCtrl,
              decoration: const InputDecoration(labelText: 'Người quan trắc'),
              onChanged: (v) => entry.inspector = v,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: weatherCtrl,
              decoration: const InputDecoration(labelText: 'Thời tiết'),
              onChanged: (v) => entry.weather = v,
            ),
            const Divider(height: 20),

            // Measurements
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: tempCtrl,
                    decoration: const InputDecoration(labelText: 'Nhiệt độ (°C)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => entry.temp = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: humidCtrl,
                    decoration: const InputDecoration(labelText: 'Độ ẩm (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => entry.humidity = double.tryParse(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Photo picker
            if (entry.photoPath != null)
              Image.file(File(entry.photoPath!), height: 100),
            ElevatedButton.icon(
              onPressed: widget.onPickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Chọn ảnh'),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

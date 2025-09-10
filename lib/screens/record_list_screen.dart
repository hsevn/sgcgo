import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/job_measurement.dart';
import 'package:url_launcher/url_launcher.dart';

class RecordListScreen extends StatefulWidget {
  final String companyName;
  final String companyAddress;
  const RecordListScreen({
    super.key,
    required this.companyName,
    required this.companyAddress,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  late final Box<JobMeasurement> box;
  late final Future<void> _initFuture;
  List<Map<String, dynamic>> locationData = [];

  bool phoneVisible = false;

  @override
  void initState() {
    super.initState();
    box = Hive.box<JobMeasurement>('measurements');
    _initFuture = _loadAssets();
  }

  Future<void> _loadAssets() async {
    final rawLoc = await rootBundle.loadString('assets/phan_cap.json');
    locationData = List<Map<String, dynamic>>.from(json.decode(rawLoc));
  }

  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Không mở được Google Maps');
    }
  }

  void saveDraft() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Đã lưu nháp')));
  void submit() => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Đã lưu & Gửi')));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return _buildMainUI(context);
      },
    );
  }

  Widget _buildMainUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFFB3E5FC),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "BIÊN BẢN QUAN TRẮC MÔI TRƯỜNG LAO ĐỘNG",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildObservationInfo(),
            const SizedBox(height: 16),
            ValueListenableBuilder<Box<JobMeasurement>>(
              valueListenable: box.listenable(),
              builder: (context, box, _) {
                final entries = box.values.toList();
                if (entries.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final jm = JobMeasurement();
                    jm.companyId = widget.companyName;
                    box.add(jm);
                  });
                  return const SizedBox();
                }
                return Column(
                  children: entries.map(_buildMeasurementCard).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saveDraft,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DD0E1),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    child: const Text("Lưu nháp",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DD0E1),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    child: const Text("Lưu & Gửi",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 🟣 Customer Info UI
  Widget _buildCustomerInfo() {
    return Column(
      children: [
        // Company Name Row
        Row(
          children: [
            _buildChip("Tên"),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueBox(widget.companyName),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Address Row
        Row(
          children: [
            _buildChip("Địa chỉ"),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueBox(widget.companyAddress),
            ),
            const SizedBox(width: 8),
            _buildIconBox(Icons.location_on,
                onTap: () => _openMap(widget.companyAddress)),
          ],
        ),
        const SizedBox(height: 12),

        // Contact Row
        Row(
          children: [
            _buildChip("Liên hệ"),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueBox("Tên KH: Nguyễn Văn A"),
            ),
            const SizedBox(width: 8),
            _buildIconBox(
              phoneVisible ? Icons.visibility_off : Icons.visibility,
              onTap: () => setState(() => phoneVisible = !phoneVisible),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB39DDB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      );

  Widget _buildValueBox(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4DD0E1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );

  Widget _buildIconBox(IconData icon, {VoidCallback? onTap}) => Container(
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 24),
          onPressed: onTap,
        ),
      );

  // 🟣 Observation Info
  Widget _buildObservationInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard([
            "Người QT: Nguyễn Văn B",
            "Ngày QT: 05/9/2025",
            "Thời tiết: nắng, không mưa",
            "Ca làm việc: 2 ca",
            "Tổng số người LĐ: 2846",
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard([
            "Giờ vào: 08 giờ 30",
            "VKH lúc vào: nắng, gió nhẹ",
            "Giờ ra: 13 giờ 30",
            "VKH lúc ra: nắng, gió nhẹ",
            "Đại diện KH: Nguyễn Văn C",
          ]),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<String> lines) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4DD0E1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      );

  // 🟣 Measurement Card
  Widget _buildMeasurementCard(JobMeasurement entry) {
    final idx = box.values.toList().indexOf(entry) + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4DD0E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Điểm $idx",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildAddButton(),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdownRow(entry),
          const SizedBox(height: 16),
          _buildIndicatorsGrid(),
          const SizedBox(height: 16),
          _buildPhotoAndDescription(idx),
        ],
      ),
    );
  }

  Widget _buildAddButton() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4DD0E1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: TextButton.icon(
          onPressed: () {
            final jm = JobMeasurement();
            jm.companyId = widget.companyName;
            box.add(jm);
          },
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          label: const Text("Thêm thẻ",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _buildDropdownRow(JobMeasurement entry) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildValueBox("Kho nguyên liệu"),
              const SizedBox(height: 8),
              _buildValueBox("L2_NAME"),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              _buildValueBox("L1_NAME"),
              const SizedBox(height: 8),
              _buildValueBox("L3_NAME"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorsGrid() {
    final indicators = [
      {"title": "Ánh sáng", "unit": "Lux", "value": "234"},
      {"title": "Ôn chung", "unit": "dB", "value": "64,5"},
      {"title": "Nhiệt độ", "unit": "°C", "value": "21,3"},
      {"title": "Độ ẩm", "unit": "%", "value": "32,3"},
      {"title": "Tốc độ gió", "unit": "m/s", "value": "0,12"},
      {"title": "Rung", "unit": "mm/s2", "value": "R"},
      {"title": "Điện trường", "unit": "KV/m", "value": "0,21"},
      {"title": "Từ trường", "unit": "MA/m", "value": "0,013"},
      {"title": "Bụi toàn phần", "unit": "mg/m³", "value": "0,13"},
      {"title": "Bức xạ nhiệt", "unit": "°C", "value": "22,3"},
      {"title": "O2", "unit": "%", "value": "0,16"},
      {"title": "CO", "unit": "ppm", "value": "K1"},
      {"title": "CO2", "unit": "ppm", "value": "650"},
      {"title": "SO2", "unit": "ppm", "value": "K1"},
      {"title": "NO2", "unit": "ppm", "value": "K1"},
    ];

    return GridView.count(
      crossAxisCount: 5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: [
        ...indicators.map((e) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4DD0E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e['title']!,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1BEE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e['value']!,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 2),
                  Text(e['unit']!,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black87),
                      textAlign: TextAlign.center),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPhotoAndDescription(int idx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // OWAS Photo Button
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("OWAS",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DD0E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Ảnh $idx",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        // Description
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4DD0E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Mô tả tư thế lao động",
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  "Nhân viên công đoạn này có nhiệm vụ cho liệu vào máy Chỉnh lý...",
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        // Add Indicator Button
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4DD0E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Thêm chỉ tiêu",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4DD0E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.blue, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

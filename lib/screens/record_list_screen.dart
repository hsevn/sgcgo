import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job_measurement.dart';
import 'package:url_launcher/url_launcher.dart';

// Lớp StateHelper để quản lý trạng thái của mỗi card "Điểm Đo"
class MeasurementPointState {
  final TextEditingController areaController = TextEditingController();
  final TextEditingController postureController = TextEditingController();
  final Map<String, TextEditingController> indicatorControllers = {};

  String? selectedL1;
  String? selectedL2;
  String? selectedL3;
  File? owasImage;

  MeasurementPointState(List<String> indicators) {
    for (var indicator in indicators) {
      indicatorControllers[indicator] = TextEditingController();
    }
  }

  void dispose() {
    areaController.dispose();
    postureController.dispose();
    for (var controller in indicatorControllers.values) {
      controller.dispose();
    }
  }
}

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
  // === COLOR & STYLE CONSTANTS ===
  static const Color scaffoldBgColor = Color(0xFFE4F9FF);
  static const Color appBarColor = Color(0xFFD5F2F8);
  static const Color primaryTealColor = Color(0xFF4DD0E1);
  static const Color lightTealColor = Color(0xFFB2EBF2);
  static const Color chipPurpleColor = Color(0xFFB39DDB);
  static const Color iconPurpleColor = Color(0xFF673AB7);
  static const Color valueTextColor = Color(0xFF005662);

  // === STATE VARIABLES ===
  bool phoneVisible = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _phanCapData = [];
  List<String> _allL1Options = [];

  final List<String> _indicators = [
    'Ánh sáng',
    'Ồn chung',
    'Nhiệt độ',
    'Độ ẩm',
    'Tốc độ gió',
    'Rung',
    'Điện trường',
    'Từ trường',
    'Bụi toàn phần',
    'Bức xạ nhiệt',
    'O2',
    'CO',
    'CO2',
    'SO2',
    'NO2'
  ];

  // Danh sách các đơn vị tương ứng
  final Map<String, String> _indicatorUnits = {
    'Ánh sáng': 'Lux',
    'Ồn chung': 'dB',
    'Nhiệt độ': '°C',
    'Độ ẩm': '%',
    'Tốc độ gió': 'm/s',
    'Rung': 'mm/s2',
    'Điện trường': 'KV/m',
    'Từ trường': 'MA/m',
    'Bụi toàn phần': 'mg/m³',
    'Bức xạ nhiệt': '°C',
    'O2': '%',
    'CO': 'ppm',
    'CO2': 'ppm',
    'SO2': 'ppm',
    'NO2': 'ppm'
  };

  final List<MeasurementPointState> _measurementPoints = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndInitialize();
  }

  @override
  void dispose() {
    for (var point in _measurementPoints) {
      point.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDataAndInitialize() async {
    final rawData = await rootBundle.loadString('assets/phan_cap.json');
    final List<dynamic> jsonData = json.decode(rawData);

    setState(() {
      _phanCapData = List<Map<String, dynamic>>.from(jsonData);
      _allL1Options =
          _phanCapData.map((e) => e['L1_NAME'].toString()).toSet().toList();

      if (_measurementPoints.isEmpty) {
        _addMeasurementPoint();
      }
      _isLoading = false;
    });
  }

  void _addMeasurementPoint() {
    setState(() {
      _measurementPoints.add(MeasurementPointState(_indicators));
    });
  }

  void _removeMeasurementPoint(int index) {
    setState(() {
      _measurementPoints[index].dispose();
      _measurementPoints.removeAt(index);
    });
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _measurementPoints[index].owasImage = File(pickedFile.path);
      });
    }
  }

  void _saveDraft() {
    // ... (logic lưu nháp giữ nguyên)
  }

  void _submit() {
    // ... (logic gửi giữ nguyên)
  }

  Future<void> _openMap(String address) async {
    final Uri url =
        Uri.parse("https://maps.google.com/?q=${Uri.encodeComponent(address)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Không mở được Google Maps');
    }
  }

  // === UI BUILDING ===
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 1,
        backgroundColor: appBarColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: iconPurpleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, size: 28, color: Colors.white),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "BIÊN BẢN QUAN TRẮC MÔI TRƯỜNG LAO ĐỘNG",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildObservationInfo(),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _measurementPoints.length,
              itemBuilder: (context, index) {
                return _buildMeasurementCard(index);
              },
            ),
            // Nút Thêm Thẻ đã được chuyển vào trong card cuối cùng
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // === WIDGET CON TÁI SỬ DỤNG ===

  Widget _buildChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: chipPurpleColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );

  Widget _buildValueBox(String text, {double verticalPadding = 14}) =>
      Container(
        padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
        width: double.infinity,
        decoration: BoxDecoration(
          color: lightTealColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueTextColor)),
      );

  Widget _buildIconBox(IconData icon, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: iconPurpleColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );

  Widget _buildStyledDropdown(int pointIndex,
      {String? hint,
      String? value,
      required List<String> items,
      required Function(String?, int) onChanged}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lightTealColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint ?? "Chọn...",
              style: TextStyle(color: valueTextColor.withOpacity(0.7))),
          value: value,
          icon: const Icon(Icons.arrow_drop_down,
              color: iconPurpleColor, size: 32),
          dropdownColor: appBarColor,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: valueTextColor),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) => onChanged(val, pointIndex),
        ),
      ),
    );
  }

  // === CÁC KHỐI GIAO DIỆN CHÍNH ===

  Widget _buildCustomerInfo() {
    return Column(
      children: [
        Row(
          children: [
            _buildChip("Tên"),
            const SizedBox(width: 12),
            Expanded(child: _buildValueBox(widget.companyName)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChip("Địa chỉ"),
            const SizedBox(width: 12),
            Expanded(child: _buildValueBox(widget.companyAddress)),
            const SizedBox(width: 8),
            _buildIconBox(Icons.location_on_rounded,
                onTap: () => _openMap(widget.companyAddress)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChip("Liên hệ"),
            const SizedBox(width: 12),
            Expanded(child: _buildValueBox("Tên KH: Nguyễn Văn A")),
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

  Widget _buildObservationInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _buildInfoCard([
          "Người QT: Nguyễn Văn B",
          "Ngày QT: 05/9/2025",
          "Thời tiết: nắng, không mưa",
          "Ca làm việc: 2 ca",
          "Tổng số người LĐ: 2846",
        ])),
        const SizedBox(width: 12),
        Expanded(
            child: _buildInfoCard([
          "Giờ vào: 08 giờ 30",
          "VKH lúc vào: nắng, gió nhẹ",
          "Giờ ra: 13 giờ 30",
          "VKH lúc ra: nắng, gió nhẹ",
          "Đại diện KH: Nguyễn Văn C",
        ])),
      ],
    );
  }

  Widget _buildInfoCard(List<String> lines) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryTealColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                  ))
              .toList(),
        ),
      );

  Widget _buildMeasurementCard(int index) {
    final pointState = _measurementPoints[index];

    final l2Options = pointState.selectedL1 != null
        ? _phanCapData
            .where((e) => e['L1_NAME'] == pointState.selectedL1)
            .map((e) => e['L2_NAME'].toString())
            .toSet()
            .toList()
        : <String>[];
    final l3Options = pointState.selectedL2 != null
        ? _phanCapData
            .where((e) =>
                e['L1_NAME'] == pointState.selectedL1 &&
                e['L2_NAME'] == pointState.selectedL2)
            .map((e) => e['L3_NAME'].toString())
            .toSet()
            .toList()
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Điểm đo ${index + 1}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_measurementPoints.length > 1)
                _buildIconBox(Icons.delete_outline_rounded,
                    onTap: () => _removeMeasurementPoint(index)),
              if (index == _measurementPoints.length - 1) ...[
                const SizedBox(width: 8),
                _buildAddButton()
              ]
            ],
          ),
          const SizedBox(height: 16),
          _buildValueBox("Kho nguyên liệu",
              verticalPadding: 16), // Sẽ thay bằng TextField sau
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Column(
                children: [
                  _buildStyledDropdown(index,
                      hint: "L1_NAME",
                      value: pointState.selectedL1,
                      items: _allL1Options, onChanged: (val, idx) {
                    setState(() {
                      _measurementPoints[idx].selectedL1 = val;
                      _measurementPoints[idx].selectedL2 = null;
                      _measurementPoints[idx].selectedL3 = null;
                    });
                  }),
                  const SizedBox(height: 8),
                  _buildStyledDropdown(index,
                      hint: "L2_NAME",
                      value: pointState.selectedL2,
                      items: l2Options, onChanged: (val, idx) {
                    setState(() {
                      _measurementPoints[idx].selectedL2 = val;
                      _measurementPoints[idx].selectedL3 = null;
                    });
                  }),
                ],
              )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 16),
                child: Icon(Icons.arrow_downward_rounded,
                    color: Colors.grey.shade400),
              ),
              Expanded(
                  child: Column(
                children: [
                  _buildStyledDropdown(index,
                      hint: "L3_NAME",
                      value: pointState.selectedL3,
                      items: l3Options, onChanged: (val, idx) {
                    setState(() {
                      _measurementPoints[idx].selectedL3 = val;
                    });
                  }),
                ],
              ))
            ],
          ),
          const SizedBox(height: 16),
          _buildIndicatorsGrid(pointState),
          const SizedBox(height: 16),
          _buildPhotoAndDescription(index),
        ],
      ),
    );
  }

  Widget _buildIndicatorsGrid(MeasurementPointState pointState) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: _indicators.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final indicatorName = _indicators[index];
        final unit = _indicatorUnits[indicatorName] ?? '';
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: lightTealColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(indicatorName,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: valueTextColor),
                  textAlign: TextAlign.center),
              SizedBox(
                height: 30,
                child: TextField(
                  controller: pointState.indicatorControllers[indicatorName],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              Text(unit,
                  style: TextStyle(
                      fontSize: 10, color: valueTextColor.withOpacity(0.8)),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoAndDescription(int index) {
    final pointState = _measurementPoints[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _pickImage(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: chipPurpleColor,
              borderRadius: BorderRadius.circular(16),
              image: pointState.owasImage != null
                  ? DecorationImage(
                      image: FileImage(pointState.owasImage!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: pointState.owasImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("OWAS",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: lightTealColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text("Ảnh ${index + 1}",
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: valueTextColor)),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 80,
            decoration: BoxDecoration(
              color: lightTealColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
                "Nhân viên công đoạn này có nhiệm vụ cho liệu vào máy Chỉnh lý...",
                style: TextStyle(fontSize: 12, color: valueTextColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _addMeasurementPoint,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconPurpleColor, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: iconPurpleColor, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text("Thêm thẻ",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _saveDraft,
            style: ElevatedButton.styleFrom(
              backgroundColor: lightTealColor,
              foregroundColor: valueTextColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              elevation: 0,
            ),
            child: const Text("Lưu nháp",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTealColor,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
            ),
            child: const Text("Lưu & Gửi",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ]);
  }
}

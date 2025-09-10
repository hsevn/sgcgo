import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // <--- DÒNG BỊ THIẾU ĐÃ ĐƯỢC THÊM VÀO ĐÂY
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job_measurement.dart'; // Đảm bảo đường dẫn này đúng
import 'package:url_launcher/url_launcher.dart';

// --- LỚP MỚI ĐỂ QUẢN LÝ TỪNG CHỈ TIÊU ĐO ---
class Indicator {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final bool isCustom; // Cờ để xác định đây có phải là chỉ tiêu mới không

  Indicator(
      {required String name,
      required String value,
      required String unit,
      this.isCustom = false})
      : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value),
        unitController = TextEditingController(text: unit);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
    unitController.dispose();
  }
}

// --- LỚP QUẢN LÝ TRẠNG THÁI CHO TỪNG ĐIỂM ĐO ---
class MeasurementPointState {
  final TextEditingController areaController =
      TextEditingController(text: "Kho nguyên liệu");
  final TextEditingController postureController = TextEditingController(
      text: "Nhân viên công đoạn này có nhiệm vụ cho liệu vào máy Chỉnh lý...");

  // Danh sách các chỉ tiêu, giờ đây là một danh sách các đối tượng Indicator
  final List<Indicator> indicators = [];

  String? selectedL1;
  String? selectedL2;
  String? selectedL3;
  File? owasImage;

  MeasurementPointState(Map<String, String> initialNames,
      Map<String, String> initialValues, Map<String, String> initialUnits) {
    initialNames.forEach((key, name) {
      indicators.add(Indicator(
        name: name,
        value: initialValues[key] ?? '',
        unit: initialUnits[key] ?? '',
      ));
    });
  }

  void dispose() {
    areaController.dispose();
    postureController.dispose();
    for (var indicator in indicators) {
      indicator.dispose();
    }
  }
}

// --- WIDGET CHÍNH CỦA MÀN HÌNH ---
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
  // === CÁC HẰNG SỐ ===
  static const Color scaffoldBgColor = Color(0xFFE6F7FB);
  static const Color appBarColor = Color(0xFFE6F7FB);
  static const Color cardBgColor = Colors.white;
  static const Color primaryTealColor = Color(0xFF4DD0E1);
  static const Color lightTealColor = Color(0xFFB2EBF2);
  static const Color chipPurpleColor = Color(0xFFB39DDB);
  static const Color iconPurpleColor = Color(0xFF673AB7);
  static const Color valueTextColor = Color(0xFF005662);
  static const Color labelTextColor = Colors.black54;

  // === BIẾN TRẠNG THÁI ===
  bool phoneVisible = false;
  bool _isLoading = true;

  // Controllers cho thông tin chung
  final TextEditingController _nguoiQTController =
      TextEditingController(text: "Nguyễn Văn B");
  final TextEditingController _ngayQTController =
      TextEditingController(text: "05/9/2025");
  final TextEditingController _thoiTietController =
      TextEditingController(text: "nắng, không mưa");
  final TextEditingController _caLamViecController =
      TextEditingController(text: "2 ca");
  final TextEditingController _tongLDController =
      TextEditingController(text: "2846");
  final TextEditingController _gioVaoController =
      TextEditingController(text: "08 giờ 30");
  final TextEditingController _vkhVaoController =
      TextEditingController(text: "nắng, gió nhẹ");
  final TextEditingController _gioRaController =
      TextEditingController(text: "13 giờ 30");
  final TextEditingController _vkhRaController =
      TextEditingController(text: "nắng, gió nhẹ");
  final TextEditingController _daiDienKHController =
      TextEditingController(text: "Nguyễn Văn C");

  // Dữ liệu dropdown
  List<Map<String, dynamic>> _phanCapData = [];
  List<String> _allL1Options = [];

  // Dữ liệu ban đầu cho các chỉ số
  final Map<String, String> _indicatorNames = {
    'light': 'Ánh sáng',
    'noise': 'Ồn chung',
    'temp': 'Nhiệt độ',
    'humidity': 'Độ ẩm',
    'wind': 'Tốc độ gió',
    'vibration': 'Rung',
    'electric': 'Điện trường',
    'magnetic': 'Từ trường',
    'dust': 'Bụi toàn phần',
    'heat': 'Bức xạ nhiệt',
    'o2': 'O2',
    'co': 'CO',
    'co2': 'CO2',
    'so2': 'SO2',
    'no2': 'NO2'
  };
  final Map<String, String> _indicatorUnits = {
    'light': 'Lux',
    'noise': 'dB',
    'temp': '°C',
    'humidity': '%',
    'wind': 'm/s',
    'vibration': 'mm/s2',
    'electric': 'KV/m',
    'magnetic': 'MA/m',
    'dust': 'mg/m³',
    'heat': '°C',
    'o2': '%',
    'co': 'ppm',
    'co2': 'ppm',
    'so2': 'ppm',
    'no2': 'ppm'
  };
  final Map<String, String> _indicatorInitialValues = {
    'light': '234',
    'noise': '64,5',
    'temp': '21,3',
    'humidity': '32,3',
    'wind': '0.12',
    'vibration': 'R',
    'electric': '0,21',
    'magnetic': '0,013',
    'dust': '0,13',
    'heat': '22,3',
    'o2': '0,16',
    'co': 'K1',
    'co2': '650',
    'so2': 'K1',
    'no2': 'K1'
  };

  // Danh sách quản lý state của từng "Điểm Đo"
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
    _nguoiQTController.dispose();
    _ngayQTController.dispose();
    _thoiTietController.dispose();
    _caLamViecController.dispose();
    _tongLDController.dispose();
    _gioVaoController.dispose();
    _vkhVaoController.dispose();
    _gioRaController.dispose();
    _vkhRaController.dispose();
    _daiDienKHController.dispose();
    super.dispose();
  }

  // --- LOGIC & HÀNH VI ---

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

  void _addMeasurementPoint() =>
      setState(() => _measurementPoints.add(MeasurementPointState(
          _indicatorNames, _indicatorInitialValues, _indicatorUnits)));

  void _removeMeasurementPoint(int index) {
    setState(() {
      _measurementPoints[index].dispose();
      _measurementPoints.removeAt(index);
    });
  }

  void _addCustomIndicator(int pointIndex) {
    setState(() {
      _measurementPoints[pointIndex]
          .indicators
          .add(Indicator(name: '---', value: '', unit: '---', isCustom: true));
    });
  }

  void _removeIndicator(int pointIndex, int indicatorIndex) {
    setState(() {
      _measurementPoints[pointIndex].indicators[indicatorIndex].dispose();
      _measurementPoints[pointIndex].indicators.removeAt(indicatorIndex);
    });
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(
          () => _measurementPoints[index].owasImage = File(pickedFile.path));
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép vào clipboard')));
  }

  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')));
    }
  }

  // --- PHẦN GIAO DIỆN (UI BUILD) ---
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
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 24, color: Colors.white),
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "BIÊN BẢN QUAN TRẮC MÔI TRƯỜNG LAO ĐỘNG",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
              itemBuilder: (context, index) => _buildMeasurementCard(index),
            ),
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  // --- CÁC WIDGET CON ĐỂ TÁI SỬ DỤNG ---

  Widget _buildChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: chipPurpleColor, borderRadius: BorderRadius.circular(24)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      );

  Widget _buildValueBox(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
            color: lightTealColor, borderRadius: BorderRadius.circular(24)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueTextColor)),
      );

  Widget _buildIconBox(IconData icon, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
              color: iconPurpleColor, borderRadius: BorderRadius.circular(24)),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );

  Widget _buildStyledTextField(
      {required TextEditingController controller,
      required String label,
      Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelTextColor)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: valueTextColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: lightTealColor,
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        )
      ],
    );
  }

  Widget _buildStyledDropdown(
      {required String hint,
      String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: lightTealColor, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: valueTextColor.withOpacity(0.7))),
          value: value,
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: iconPurpleColor, size: 36),
          dropdownColor: appBarColor,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: valueTextColor),
          items: items
              .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- CÁC KHỐI GIAO DIỆN CHÍNH ---

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              _buildChip("Tên"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox(widget.companyName)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildChip("Địa chỉ"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox(widget.companyAddress)),
              const SizedBox(width: 8),
              _buildIconBox(Icons.location_on_rounded,
                  onTap: () => _openMap(widget.companyAddress)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _buildChip("Liên hệ"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox("Tên KH: Nguyễn Văn A")),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildValueBox(
                      phoneVisible ? "0912 345 678" : "•0912...678")),
              const SizedBox(width: 8),
              _buildIconBox(
                  phoneVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  onTap: () => setState(() => phoneVisible = !phoneVisible)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationInfo() {
    return LayoutBuilder(builder: (context, constraints) {
      bool isNarrow = constraints.maxWidth < 600;
      return Card(
        elevation: 0,
        color: cardBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isNarrow
              ? Column(children: _buildInfoContent())
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildInfoContent(isRow: true)),
        ),
      );
    });
  }

  List<Widget> _buildInfoContent({bool isRow = false}) {
    final content = [
      Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        _buildStyledTextField(
            label: "Người QT",
            controller: _nguoiQTController,
            suffixIcon: IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copyToClipboard(_nguoiQTController.text))),
        const SizedBox(height: 8),
        _buildStyledTextField(label: "Ngày QT", controller: _ngayQTController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "Thời tiết", controller: _thoiTietController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "Ca làm việc", controller: _caLamViecController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "Tổng số người LĐ", controller: _tongLDController),
      ])),
      SizedBox(width: isRow ? 16 : 0, height: isRow ? 0 : 16),
      Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        _buildStyledTextField(label: "Giờ vào", controller: _gioVaoController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "VKH lúc vào", controller: _vkhVaoController),
        const SizedBox(height: 8),
        _buildStyledTextField(label: "Giờ ra", controller: _gioRaController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "VKH lúc ra", controller: _vkhRaController),
        const SizedBox(height: 8),
        _buildStyledTextField(
            label: "Đại diện KH", controller: _daiDienKHController),
      ])),
    ];
    return content;
  }

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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("Điểm đo ${index + 1}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (index > 0)
                _buildIconBox(Icons.delete_outline_rounded,
                    onTap: () => _removeMeasurementPoint(index)),
              if (index == _measurementPoints.length - 1) ...[
                const SizedBox(width: 8),
                _buildAddButton("Thêm thẻ", _addMeasurementPoint),
              ]
            ]),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: pointState.areaController,
                            decoration: InputDecoration(
                                labelText: "Khu vực đo",
                                filled: true,
                                fillColor: lightTealColor,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14)))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStyledDropdown(
                            hint: "L1_NAME",
                            value: pointState.selectedL1,
                            items: _allL1Options,
                            onChanged: (val) => setState(() {
                                  pointState.selectedL1 = val;
                                  pointState.selectedL2 = null;
                                  pointState.selectedL3 = null;
                                }))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _buildStyledDropdown(
                            hint: "L2_NAME",
                            value: pointState.selectedL2,
                            items: l2Options,
                            onChanged: (val) => setState(() {
                                  pointState.selectedL2 = val;
                                  pointState.selectedL3 = null;
                                }))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStyledDropdown(
                            hint: "L3_NAME",
                            value: pointState.selectedL3,
                            items: l3Options,
                            onChanged: (val) =>
                                setState(() => pointState.selectedL3 = val))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIndicatorsGrid(index),
            const SizedBox(height: 16),
            _buildPhotoAndDescription(index),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsGrid(int pointIndex) {
    final pointState = _measurementPoints[pointIndex];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1),
      itemCount: pointState.indicators.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, indicatorIndex) {
        final indicator = pointState.indicators[indicatorIndex];
        return Container(
          decoration: BoxDecoration(
              color: lightTealColor, borderRadius: BorderRadius.circular(16)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                        height: 20,
                        child: TextField(
                          controller: indicator.nameController,
                          readOnly: !indicator.isCustom,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: valueTextColor),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero),
                        )),
                    SizedBox(
                        height: 32,
                        child: TextField(
                          controller: indicator.valueController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none)),
                        )),
                    SizedBox(
                        height: 20,
                        child: TextField(
                          controller: indicator.unitController,
                          readOnly: !indicator.isCustom,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color: valueTextColor.withOpacity(0.8)),
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero),
                        )),
                  ],
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: InkWell(
                  onTap: () => _removeIndicator(pointIndex, indicatorIndex),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.redAccent, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoAndDescription(int index) {
    final pointState = _measurementPoints[index];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    image: FileImage(pointState.owasImage!), fit: BoxFit.cover)
                : null,
          ),
          child: pointState.owasImage == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("OWAS",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: lightTealColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text("Ảnh ${index + 1}",
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: valueTextColor)),
                  ),
                ])
              : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: TextField(
        controller: pointState.postureController,
        maxLines: 3,
        decoration: InputDecoration(
            filled: true,
            fillColor: lightTealColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12)),
      )),
      const SizedBox(width: 8),
      _buildAddButton("Thêm chỉ tiêu", () => _addCustomIndicator(index)),
    ]);
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: iconPurpleColor, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
                color: iconPurpleColor, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        Expanded(
            child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: lightTealColor,
                      foregroundColor: valueTextColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                      elevation: 0),
                  child: const Text("Lưu nháp",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ))),
        const SizedBox(width: 16),
        Expanded(
            child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTealColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26))),
                  child: const Text("Lưu & Gửi",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ))),
      ]),
    );
  }
}

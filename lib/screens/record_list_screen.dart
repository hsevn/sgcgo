import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/job_measurement.dart';
import 'package:url_launcher/url_launcher.dart';

// --- LỚP HELPER QUẢN LÝ TỪNG CHỈ TIÊU ĐO ---
class Indicator {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final bool isCustom;
  final bool isDeletable;

  Indicator(
      {required String name,
      required String value,
      this.isCustom = false,
      this.isDeletable = true})
      : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

// --- LỚP HELPER QUẢN LÝ TRẠNG THÁI CỦA MỖI ĐIỂM ĐO ---
class MeasurementPointState {
  final TextEditingController areaController;
  final TextEditingController postureController =
      TextEditingController(text: "Nhân viên công đoạn này có nhiệm vụ...");
  final List<Indicator> indicators = [];
  final bool
      isRemovable; // <-- THAY ĐỔI: Đổi tên thành isRemovable để rõ nghĩa hơn
  String? selectedL1, selectedL2, selectedL3;
  File? owasImage;

  MeasurementPointState({
    required String areaName,
    required Map<String, String> initialNames,
    required Map<String, String> initialValues,
    this.isRemovable = false, // Mặc định là không thể xóa
  }) : areaController = TextEditingController(text: areaName) {
    initialNames.forEach((key, name) {
      indicators.add(Indicator(
        name: name,
        value: initialValues[key] ?? '',
        isDeletable: false, // Các chỉ tiêu mặc định không xóa được
        isCustom: false,
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
  const RecordListScreen(
      {super.key, required this.companyName, required this.companyAddress});
  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  // === HẰNG SỐ ===
  static const Color scaffoldBgColor = Color(0xFFE6F7FB);
  static const Color appBarColor = Color(0xFFE6F7FB);
  static const Color cardBgColor = Colors.white;
  static const Color cardHighlightColor = Color(0xFFFFF9C4);
  static const Color primaryTealColor = Color(0xFF4DD0E1);
  static const Color lightTealColor = Color(0xFFB2EBF2);
  static const Color chipPurpleColor = Color(0xFFB39DDB);
  static const Color iconPurpleColor = Color(0xFF673AB7);
  static const Color valueTextColor = Color(0xFF005662);
  static const Color labelTextColor = Colors.black54;

  // === BIẾN TRẠNG THÁI ===
  int? _currentlySelectedCardIndex;
  bool phoneVisible = false;
  bool _isLoading = true;

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

  List<Map<String, dynamic>> _phanCapData = [];
  List<String> _allL1Options = [];

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

  Future<void> _loadDataAndInitialize() async {
    try {
      final rawData = await rootBundle.loadString('assets/phan_cap.json');
      final List<dynamic> jsonData = json.decode(rawData);
      setState(() {
        _phanCapData = List<Map<String, dynamic>>.from(jsonData);
        _allL1Options =
            _phanCapData.map((e) => e['L1_NAME'].toString()).toSet().toList();
        if (_measurementPoints.isEmpty) {
          _addInitialMeasurementPoints();
        }
        _isLoading = false;
      });
    } catch (e) {
      print("LỖI KHI TẢI phan_cap.json: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lỗi: Không thể tải dữ liệu phân cấp.')));
      }
    }
  }

  void _addInitialMeasurementPoints() {
    final areaNames = [
      "Kho nguyên liệu",
      "Khu vực sản xuất",
      "Khu vực đóng gói",
      "Văn phòng làm việc",
      "Nhà ăn công nhân",
      "Xưởng cơ khí",
      "Phòng thí nghiệm",
      "Khu xử lý nước thải",
      "Trạm biến áp",
      "Bãi xe công ty"
    ];
    for (final name in areaNames) {
      _measurementPoints.add(MeasurementPointState(
          areaName: name,
          initialNames: _indicatorNames,
          initialValues: _indicatorInitialValues,
          isRemovable: false)); // Không thể xóa
    }
  }

  void _addMeasurementPoint() =>
      setState(() => _measurementPoints.add(MeasurementPointState(
          areaName: "Vị trí đo mới",
          initialNames: _indicatorNames,
          initialValues: _indicatorInitialValues,
          isRemovable: true))); // Có thể xóa
  void _removeMeasurementPoint(int index) => setState(() {
        if (_measurementPoints[index].isRemovable) {
          // Chỉ xóa nếu là thẻ có thể xóa
          _measurementPoints[index].dispose();
          _measurementPoints.removeAt(index);
          if (_currentlySelectedCardIndex == index) {
            _currentlySelectedCardIndex =
                null; // Bỏ chọn nếu thẻ đang chọn bị xóa
          } else if (_currentlySelectedCardIndex != null &&
              _currentlySelectedCardIndex! > index) {
            _currentlySelectedCardIndex = _currentlySelectedCardIndex! -
                1; // Điều chỉnh chỉ số nếu thẻ đang chọn nằm sau thẻ bị xóa
          }
        }
      });
  void _addCustomIndicator(int pointIndex) =>
      setState(() => _measurementPoints[pointIndex].indicators.add(Indicator(
          name: '---', value: '', isCustom: true, isDeletable: true)));
  void _removeIndicator(int pointIndex, int indicatorIndex) => setState(() {
        _measurementPoints[pointIndex].indicators[indicatorIndex].dispose();
        _measurementPoints[pointIndex].indicators.removeAt(indicatorIndex);
      });
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
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã sao chép')));
  }

  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse(
        "http://googleusercontent.com/maps/google.com/1{Uri.encodeComponent(address)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        toolbarHeight: 56,
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
                        size: 22, color: Colors.white)))),
        centerTitle: true,
        title: const Text("BIÊN BẢN QUAN TRẮC",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ),
      body: Scrollbar(
        thumbVisibility: true, // Luôn hiển thị thanh cuộn
        thickness: 10.0, // Tăng độ dày thanh cuộn
        radius: const Radius.circular(10),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildObservationInfo(),
            const SizedBox(height: 16),
            for (var i = 0; i < _measurementPoints.length; i++)
              _buildMeasurementCard(i),
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildChip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: chipPurpleColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)));
  Widget _buildValueBox(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
          color: lightTealColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueTextColor)));
  Widget _buildIconBox(IconData icon, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
              color: iconPurpleColor, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: Colors.white, size: 24)));
  Widget _buildStyledDropdown(
          {required String hint,
          String? value,
          required List<String> items,
          required ValueChanged<String?> onChanged}) =>
      Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: lightTealColor, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(hint,
                      style: TextStyle(
                          fontSize: 12,
                          color: valueTextColor.withOpacity(0.7))),
                  value: value,
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: iconPurpleColor, size: 32),
                  dropdownColor: appBarColor,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: valueTextColor),
                  items: items
                      .map((String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item,
                              overflow: TextOverflow.ellipsis, maxLines: 3)))
                      .toList(),
                  onChanged: onChanged)));
  Widget _buildStyledTextField(
          {required TextEditingController controller,
          required String label,
          Widget? suffixIcon}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelTextColor)),
        const SizedBox(height: 4),
        SizedBox(
            height: 42,
            child: TextField(
                controller: controller,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueTextColor),
                decoration: InputDecoration(
                    filled: true,
                    fillColor: lightTealColor,
                    suffixIcon: suffixIcon,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none))))
      ]);
  Widget _buildAddButton(String label, VoidCallback onPressed) => InkWell(
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
                child: const Icon(Icons.add, color: Colors.white, size: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w600))
          ])));

  Widget _buildCustomerInfo() => Card(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(children: [
              _buildChip("Tên"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox(widget.companyName))
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _buildChip("Địa chỉ"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox(widget.companyAddress)),
              const SizedBox(width: 8),
              _buildIconBox(Icons.location_on_rounded,
                  onTap: () => _openMap(widget.companyAddress))
            ]),
            const SizedBox(height: 10),
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
                  onTap: () => setState(() => phoneVisible = !phoneVisible))
            ])
          ])));

  Widget _buildObservationInfo() =>
      LayoutBuilder(builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 600;
        final content = _buildInfoContent(isRow: !isNarrow);
        return Card(
            elevation: 0,
            color: cardBgColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: isNarrow
                    ? Column(children: content)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: content)));
      });

  List<Widget> _buildInfoContent({bool isRow = false}) {
    final leftColumn =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      _buildStyledTextField(
          label: "Người QT",
          controller: _nguoiQTController,
          suffixIcon: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
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
          label: "Tổng số người LĐ", controller: _tongLDController)
    ]);
    final rightColumn =
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      _buildStyledTextField(label: "Giờ vào", controller: _gioVaoController),
      const SizedBox(height: 8),
      _buildStyledTextField(
          label: "VKH lúc vào", controller: _vkhVaoController),
      const SizedBox(height: 8),
      _buildStyledTextField(label: "Giờ ra", controller: _gioRaController),
      const SizedBox(height: 8),
      _buildStyledTextField(label: "VKH lúc ra", controller: _vkhRaController),
      const SizedBox(height: 8),
      _buildStyledTextField(
          label: "Đại diện KH", controller: _daiDienKHController)
    ]);
    if (isRow) {
      return [
        Expanded(child: leftColumn),
        const SizedBox(width: 16),
        Expanded(child: rightColumn)
      ];
    } else {
      return [leftColumn, const SizedBox(height: 16), rightColumn];
    }
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
    final bool isSelected = _currentlySelectedCardIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentlySelectedCardIndex =
          index), // Cập nhật trạng thái highlight khi nhấn
      child: Card(
        elevation: isSelected ? 4 : 0,
        margin: const EdgeInsets.only(bottom: 16),
        color: isSelected ? cardHighlightColor : cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isSelected
              ? BorderSide(color: Colors.amber.shade600, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text("Điểm đo ${index + 1}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (pointState
                    .isRemovable) // Chỉ hiển thị nút xóa nếu thẻ có thể xóa
                  _buildIconBox(Icons.delete_outline_rounded,
                      onTap: () => _removeMeasurementPoint(index)),
                if (index == _measurementPoints.length - 1) ...[
                  const SizedBox(width: 8),
                  _buildAddButton("Thêm thẻ", _addMeasurementPoint)
                ]
              ]),
              const SizedBox(height: 16),
              Column(children: [
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: pointState.areaController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                              labelText: "Khu vực đo",
                              labelStyle: const TextStyle(fontSize: 12),
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
                              })))
                ]),
                const SizedBox(height: 8),
                Row(children: [
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
                              setState(() => pointState.selectedL3 = val)))
                ])
              ]),
              const SizedBox(height: 16),
              _buildIndicatorsGrid(index),
              const SizedBox(height: 16),
              _buildPhotoAndDescription(index),
            ],
          ),
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
              Column(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Phân bố đều tiêu đề và trường nhập
                children: [
                  Container(
                    height: 20, // Chiều cao cố định cho tiêu đề
                    padding: const EdgeInsets.only(top: 4), // Đẩy sát lên trên
                    alignment: Alignment.topCenter,
                    child: Text(indicator.nameController.text,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: valueTextColor),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 30,
                        child: TextField(
                          controller: indicator.valueController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Padding dưới để giữ khoảng cách
                ],
              ),
              if (indicator.isDeletable)
                Positioned(
                    top: -8,
                    right: -8,
                    child: InkWell(
                        onTap: () =>
                            _removeIndicator(pointIndex, indicatorIndex),
                        child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14)))),
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
          width: 70,
          height: 70,
          decoration: BoxDecoration(
              color: chipPurpleColor,
              borderRadius: BorderRadius.circular(16),
              image: pointState.owasImage != null
                  ? DecorationImage(
                      image: FileImage(pointState.owasImage!),
                      fit: BoxFit.cover)
                  : null),
          child: pointState.owasImage == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("OWAS",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: lightTealColor,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text("Ảnh ${index + 1}",
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: valueTextColor)))
                ])
              : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: TextField(
              controller: pointState.postureController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                  filled: true,
                  fillColor: lightTealColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12)))),
      const SizedBox(width: 8),
      _buildAddButton("Thêm chỉ tiêu", () => _addCustomIndicator(index)),
    ]);
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        Expanded(
            child: SizedBox(
                height: 48,
                child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: lightTealColor,
                        foregroundColor: valueTextColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 0),
                    child: const Text("Lưu nháp",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold))))),
        const SizedBox(width: 16),
        Expanded(
            child: SizedBox(
                height: 48,
                child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTealColor,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24))),
                    child: const Text("Lưu & Gửi",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold))))),
      ]),
    );
  }
}

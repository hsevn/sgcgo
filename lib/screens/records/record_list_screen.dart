import 'dart.convert';
import 'dart.io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/odoo_api_service.dart';

// --- CÁC LỚP HELPER ---
// Lớp Indicator được giữ nguyên từ file của bạn
class Indicator {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final bool isCustom;
  final bool isDeletable;

  Indicator({
    required String name,
    required String value,
    this.isCustom = false,
    this.isDeletable = true,
  })  : nameController = TextEditingController(text: name),
        valueController = TextEditingController(text: value);

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

// Lớp MeasurementPointState được giữ nguyên từ file của bạn
class MeasurementPointState {
  final TextEditingController areaController;
  final TextEditingController postureController;
  final List<Indicator> indicators;
  final bool isRemovable;
  String? selectedL1, selectedL2, selectedL3;
  File? owasImage;

  MeasurementPointState({
    required String areaName,
    String posture = "Nhân viên công đoạn này có nhiệm vụ...",
    required Map<String, String> initialNames,
    required Map<String, String> initialValues,
    this.isRemovable = false,
  })  : areaController = TextEditingController(text: areaName),
        postureController = TextEditingController(text: posture),
        indicators = [] {
    initialNames.forEach((key, name) {
      indicators.add(Indicator(
        name: name,
        value: initialValues[key] ?? '',
        isDeletable: false,
        isCustom: false,
      ));
    });
  }

  MeasurementPointState.fromMap(Map<String, dynamic> map,
      {this.isRemovable = false})
      : areaController = TextEditingController(text: map['areaName']),
        postureController = TextEditingController(text: map['posture']),
        selectedL1 = map['selectedL1'],
        selectedL2 = map['selectedL2'],
        selectedL3 = map['selectedL3'],
        owasImage =
            map['owasImagePath'] != null ? File(map['owasImagePath']) : null,
        indicators = (map['indicators'] as List)
            .map((e) => Indicator(
                  name: e['name'],
                  value: e['value'],
                  isCustom: e['isCustom'],
                  isDeletable: e['isDeletable'],
                ))
            .toList();

  // HÀM MỚI: Dùng để tạo điểm đo từ dữ liệu Odoo (linh hoạt hơn)
  MeasurementPointState.fromOdooData({
    required String areaName,
    String posture = "",
    required List<dynamic> odooIndicators,
  })  : areaController = TextEditingController(text: areaName),
        postureController = TextEditingController(text: posture),
        isRemovable = false,
        indicators = odooIndicators
            .map((ind) => Indicator(
                  name: ind['x_name'] ?? '',
                  value: ind['x_value'] ?? '',
                  isCustom: false, // Dữ liệu từ Odoo không phải custom
                  isDeletable: false, // Dữ liệu từ Odoo không thể xóa
                ))
            .toList();

  Map<String, dynamic> toMap() {
    return {
      'areaName': areaController.text,
      'posture': postureController.text,
      'selectedL1': selectedL1,
      'selectedL2': selectedL2,
      'selectedL3': selectedL3,
      'owasImagePath': owasImage?.path,
      'indicators': indicators
          .map((e) => {
                'name': e.nameController.text,
                'value': e.valueController.text,
                'isCustom': e.isCustom,
                'isDeletable': e.isDeletable,
              })
          .toList(),
    };
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
  final int taskId;

  const RecordListScreen({
    super.key,
    required this.companyName,
    required this.companyAddress,
    required this.taskId,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  // === BIẾN TRẠNG THÁI (THÊM _isReadOnly) ===
  bool _isReadOnly = false;
  bool _isLoadingData = true;
  bool _isSending = false;
  int? _currentlySelectedCardIndex;
  bool phoneVisible = false;

  // === CONTROLLERS & DATA (GIỮ NGUYÊN) ===
  final OdooApiService _apiService = OdooApiService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final List<MeasurementPointState> _measurementPoints = [];
  late Box _recordBox;

  // ... các controllers và dữ liệu khác của bạn được giữ nguyên ...
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
  bool _bottomButtonsVisible = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Cập nhật hàm này để kiểm tra Odoo trước

    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final lastVisible = positions.last.index;
        final totalItems = _measurementPoints.length + 1;
        if (lastVisible >= totalItems && !_bottomButtonsVisible) {
          setState(() => _bottomButtonsVisible = true);
        } else if (lastVisible < totalItems && _bottomButtonsVisible) {
          setState(() => _bottomButtonsVisible = false);
        }
      }
    });
  }

  @override
  void dispose() {
    // Giữ nguyên hàm dispose của bạn
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

  // === CẬP NHẬT LOGIC TẢI DỮ LIỆU ===
  Future<void> _loadInitialData() async {
    try {
      final rawData = await rootBundle.loadString('assets/phan_cap.json');
      _phanCapData = List<Map<String, dynamic>>.from(json.decode(rawData));
      _allL1Options =
          _phanCapData.map((e) => e['L1_NAME'].toString()).toSet().toList();

      // Bước 1: Luôn kiểm tra Odoo trước
      final odooRecord =
          await _apiService.fetchMeasurementRecord(widget.taskId);
      if (odooRecord != null && mounted) {
        _populateStateFromOdoo(odooRecord);
        setState(() => _isReadOnly = true); // KHÓA MÀN HÌNH
      } else {
        // Bước 2: Nếu không có trên Odoo, mới tìm bản nháp
        _recordBox = await Hive.openBox('draft_records');
        await _loadDraftFromHive();
        setState(() => _isReadOnly = false); // MỞ KHÓA MÀN HÌNH
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _populateStateFromOdoo(Map<String, dynamic> record) {
    _nguoiQTController.text = record['x_observer'] ?? '';
    _ngayQTController.text = record['x_observation_date'] ?? '';
    _thoiTietController.text = record['x_weather'] ?? '';
    _caLamViecController.text = record['x_work_shift'] ?? '';
    _tongLDController.text = (record['x_total_workers'] ?? '0').toString();
    _gioVaoController.text = record['x_start_time'] ?? '';
    _vkhVaoController.text = record['x_start_microclimate'] ?? '';
    _gioRaController.text = record['x_end_time'] ?? '';
    _vkhRaController.text = record['x_end_microclimate'] ?? '';
    _daiDienKHController.text = record['x_customer_representative'] ?? '';

    _measurementPoints.clear();
    final pointsData =
        record['x_measurement_point_ids'] as List<dynamic>? ?? [];
    for (var pointMap in pointsData) {
      _measurementPoints.add(MeasurementPointState.fromOdooData(
        areaName: pointMap['x_name'] ?? '',
        posture: pointMap['x_posture'] ?? '',
        odooIndicators: pointMap['x_indicator_ids'] as List<dynamic>? ?? [],
      ));
    }
  }

  Future<void> _loadDraftFromHive() async {
    final savedRecord = _recordBox.get(widget.taskId);
    if (savedRecord != null) {
      _nguoiQTController.text =
          savedRecord['nguoiQT'] ?? _nguoiQTController.text;
      _ngayQTController.text = savedRecord['ngayQT'] ?? _ngayQTController.text;
      _thoiTietController.text =
          savedRecord['thoiTiet'] ?? _thoiTietController.text;
      _caLamViecController.text =
          savedRecord['caLamViec'] ?? _caLamViecController.text;
      _tongLDController.text = savedRecord['tongLD'] ?? _tongLDController.text;
      _gioVaoController.text = savedRecord['gioVao'] ?? _gioVaoController.text;
      _vkhVaoController.text = savedRecord['vkhVao'] ?? _vkhVaoController.text;
      _gioRaController.text = savedRecord['gioRa'] ?? _gioRaController.text;
      _vkhRaController.text = savedRecord['vkhRa'] ?? _vkhRaController.text;
      _daiDienKHController.text =
          savedRecord['daiDienKH'] ?? _daiDienKHController.text;

      final List<dynamic> pointsData = savedRecord['measurementPoints'] ?? [];
      _measurementPoints
          .addAll(pointsData.map((e) => MeasurementPointState.fromMap(e)));
    } else {
      _addInitialMeasurementPoints();
    }
  }

  // Các hàm logic của bạn được giữ nguyên
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
          isRemovable: false));
    }
  }

  void _addMeasurementPoint() =>
      setState(() => _measurementPoints.add(MeasurementPointState(
          areaName: "Vị trí đo mới",
          initialNames: _indicatorNames,
          initialValues: _indicatorInitialValues,
          isRemovable: true)));
  void _removeMeasurementPoint(int index) => setState(() {
        if (_measurementPoints[index].isRemovable) {
          _measurementPoints[index].dispose();
          _measurementPoints.removeAt(index);
          if (_currentlySelectedCardIndex == index)
            _currentlySelectedCardIndex = null;
          else if (_currentlySelectedCardIndex != null &&
              _currentlySelectedCardIndex! > index)
            _currentlySelectedCardIndex = _currentlySelectedCardIndex! - 1;
        }
      });
  void _addCustomIndicator(int pointIndex) =>
      setState(() => _measurementPoints[pointIndex].indicators.add(
          Indicator(name: '', value: '', isCustom: true, isDeletable: true)));
  void _removeIndicator(int pointIndex, int indicatorIndex) => setState(() {
        _measurementPoints[pointIndex].indicators[indicatorIndex].dispose();
        _measurementPoints[pointIndex].indicators.removeAt(indicatorIndex);
      });
  Future<void> _pickImage(int index) async {
    if (_isReadOnly) return;
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null)
      setState(
          () => _measurementPoints[index].owasImage = File(pickedFile.path));
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã sao chép')));
  }

  Future<void> _openMap(String address) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps')));
  }

  // --- CẬP NHẬT LOGIC LƯU & GỬI ---
  Future<void> _saveDraft() async {
    /* Giữ nguyên logic của bạn */
    if (widget.taskId == 0) return;
    final Map<String, dynamic> draftData = {
      'nguoiQT': _nguoiQTController.text,
      'ngayQT': _ngayQTController.text,
      'thoiTiet': _thoiTietController.text,
      'caLamViec': _caLamViecController.text,
      'tongLD': _tongLDController.text,
      'gioVao': _gioVaoController.text,
      'vkhVao': _vkhVaoController.text,
      'gioRa': _gioRaController.text,
      'vkhRa': _vkhRaController.text,
      'daiDienKH': _daiDienKHController.text,
      'companyName': widget.companyName,
      'companyAddress': widget.companyAddress,
      'measurementPoints': _measurementPoints.map((p) => p.toMap()).toList(),
    };
    try {
      await _recordBox.put(widget.taskId, draftData);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu biên bản nháp.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi khi lưu nháp: $e')));
    }
  }

  Future<void> _saveAndSend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận gửi'),
        content: const Text(
            'Bạn có chắc chắn muốn gửi biên bản này không? Sau khi gửi sẽ không thể chỉnh sửa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isSending = true);
    try {
      final data = {
        'x_task_id': widget.taskId,
        'x_observer': _nguoiQTController.text,
        'x_observation_date': _ngayQTController.text,
        'x_weather': _thoiTietController.text,
        'x_work_shift': _caLamViecController.text,
        'x_total_workers': int.tryParse(_tongLDController.text) ?? 0,
        'x_start_time': _gioVaoController.text,
        'x_start_microclimate': _vkhVaoController.text,
        'x_end_time': _gioRaController.text,
        'x_end_microclimate': _vkhRaController.text,
        'x_customer_representative': _daiDienKHController.text,
      };
      final pointsData = _measurementPoints
          .map((p) => {
                'x_name': p.areaController.text,
                'x_posture': p.postureController.text,
                'x_indicator_ids': p.indicators
                    .map((i) => [
                          0,
                          0,
                          {
                            'x_name': i.nameController.text,
                            'x_value': i.valueController.text
                          }
                        ])
                    .toList(),
              })
          .toList();
      final recordId =
          await _apiService.createMeasurementRecord(data, pointsData);
      final doneStageId = await _apiService.getStageIdByName('Hoàn thành');
      if (doneStageId != null)
        await _apiService.updateTaskStage(widget.taskId, doneStageId);
      await _recordBox.delete(widget.taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gửi biên bản thành công!'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true); // Trả về true để báo cho TaskList làm mới
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi khi gửi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Giao diện của bạn được giữ nguyên, chỉ thêm logic điều khiển
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
      body: Stack(
        children: [
          ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: _measurementPoints.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _buildCustomerInfo();
              if (index == 1)
                return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _buildObservationInfo());
              final cardIndex = index - 2;
              return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildMeasurementCard(cardIndex));
            },
          ),
          if (_isSending)
            Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
      floatingActionButton: _isReadOnly ? null : _buildQuickNavFAB(),
      bottomNavigationBar: (_isReadOnly || !_bottomButtonsVisible)
          ? null
          : _buildActionButtons(),
    );
  }

  // --- CÁC WIDGET GIAO DIỆN CỦA BẠN (ĐƯỢC THÊM LOGIC _isReadOnly) ---
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
      onTap: _isReadOnly ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
              color: iconPurpleColor, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: Colors.white, size: 24)));
  Widget _buildAddButton(String label, VoidCallback onPressed) => InkWell(
      onTap: _isReadOnly ? null : onPressed,
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
                  onChanged: _isReadOnly ? null : onChanged)));

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
                readOnly: _isReadOnly,
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

  Widget _buildCustomerInfo() => Card(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: [
            Row(children: [
              _buildChip("Tên Công ty"),
              const SizedBox(width: 12),
              Expanded(child: _buildValueBox(widget.companyName))
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _buildChip("Dự án"),
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
    /* Giữ nguyên của bạn */ final leftColumn =
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
    if (isRow)
      return [
        Expanded(child: leftColumn),
        const SizedBox(width: 16),
        Expanded(child: rightColumn)
      ];
    else
      return [leftColumn, const SizedBox(height: 16), rightColumn];
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
        onTap: () => setState(() => _currentlySelectedCardIndex = index),
        child: Card(
            elevation: isSelected ? 4 : 0,
            margin: const EdgeInsets.only(bottom: 0),
            color: isSelected ? cardHighlightColor : cardBgColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: isSelected
                    ? BorderSide(color: Colors.amber.shade600, width: 2)
                    : BorderSide.none),
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
                        if (!_isReadOnly && pointState.isRemovable)
                          _buildIconBox(Icons.delete_outline_rounded,
                              onTap: () => _removeMeasurementPoint(index)),
                        if (!_isReadOnly &&
                            index == _measurementPoints.length - 1) ...[
                          const SizedBox(width: 8),
                          _buildAddButton("Thêm thẻ", _addMeasurementPoint)
                        ]
                      ]),
                      const SizedBox(height: 16),
                      Column(children: [
                        Row(children: [
                          Expanded(
                              child: TextField(
                                  readOnly: _isReadOnly,
                                  controller: pointState.areaController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                      labelText: "Khu vực đo",
                                      labelStyle: const TextStyle(fontSize: 12),
                                      filled: true,
                                      fillColor: lightTealColor,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                  onChanged: (val) => setState(
                                      () => pointState.selectedL3 = val)))
                        ])
                      ]),
                      const SizedBox(height: 16),
                      _buildIndicatorsGrid(index),
                      const SizedBox(height: 16),
                      _buildPhotoAndDescription(index)
                    ]))));
  }

  Widget _buildIndicatorsGrid(int pointIndex) {
    /* Giữ nguyên của bạn với logic readOnly */ final pointState =
        _measurementPoints[pointIndex];
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
                  color: lightTealColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Stack(clipBehavior: Clip.none, children: [
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Container(
                      height: 22,
                      padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                      alignment: Alignment.topCenter,
                      child: TextField(
                          readOnly: _isReadOnly || !indicator.isCustom,
                          controller: indicator.nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: valueTextColor),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(bottom: 8),
                              hintText: indicator.isCustom ? 'Tên C.Tiêu' : '',
                              hintStyle: TextStyle(
                                  fontSize: 9,
                                  color: valueTextColor.withOpacity(0.7))))),
                  Expanded(
                      child: Center(
                          child: SizedBox(
                              height: 30,
                              child: TextField(
                                  readOnly: _isReadOnly,
                                  controller: indicator.valueController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.8),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 4),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide.none))))))
                ]),
                if (!_isReadOnly && indicator.isDeletable)
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
                                  color: Colors.white, size: 14))))
              ]));
        });
  }

  Widget _buildPhotoAndDescription(int index) {
    /* Giữ nguyên của bạn với logic readOnly */ final pointState =
        _measurementPoints[index];
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
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                  : null)),
      const SizedBox(width: 12),
      Expanded(
          child: TextField(
              readOnly: _isReadOnly,
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
      if (!_isReadOnly) ...[
        const SizedBox(width: 8),
        _buildAddButton("Thêm chỉ tiêu", () => _addCustomIndicator(index))
      ]
    ]);
  }

  Widget _buildActionButtons() {
    /* Giữ nguyên của bạn */ return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
        child: Row(children: [
          Expanded(
              child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.drafts_outlined, size: 20),
                      label: const Text("Lưu nháp",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: lightTealColor,
                          foregroundColor: valueTextColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0)))),
          const SizedBox(width: 24),
          Expanded(
              child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                      onPressed: _saveAndSend,
                      icon: const Icon(Icons.send_outlined, size: 20),
                      label: const Text("Lưu & Gửi",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTealColor,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24))))))
        ]));
  }

  Widget _buildQuickNavFAB() {
    /* Giữ nguyên của bạn */ return FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              builder: (context) => Container(
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                      itemCount: _measurementPoints.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            leading: CircleAvatar(child: Text("${index + 1}")),
                            title: Text(
                                _measurementPoints[index].areaController.text),
                            onTap: () {
                              _itemScrollController.scrollTo(
                                  index: index + 2,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic);
                              Navigator.pop(context);
                            });
                      })));
        },
        backgroundColor: iconPurpleColor,
        child: const Icon(Icons.list_alt_rounded, color: Colors.white));
  }
}

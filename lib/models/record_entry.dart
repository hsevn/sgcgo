class RecordEntry {
  final String company;
  final String area;
  final double? temperature;
  bool isSynced;

  RecordEntry({
    required this.company,
    required this.area,
    this.temperature,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'company': company,
    'area': area,
    'temperature': temperature,
    'isSynced': isSynced,
  };

  static RecordEntry fromMap(Map map) => RecordEntry(
    company: map['company'],
    area: map['area'],
    temperature: map['temperature'],
    isSynced: map['isSynced'] ?? false,
  );
}

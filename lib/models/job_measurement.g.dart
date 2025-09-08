// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_measurement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobMeasurementAdapter extends TypeAdapter<JobMeasurement> {
  @override
  final int typeId = 0;

  @override
  JobMeasurement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobMeasurement(
      companyId: fields[0] as String,
      locationL1: fields[1] as String,
      locationL2: fields[2] as String,
      locationL3: fields[3] as String,
      light: fields[4] as double,
      temperature: fields[5] as double,
      humidity: fields[6] as double,
      imagePath: fields[7] as String?,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      timestamp: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, JobMeasurement obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.companyId)
      ..writeByte(1)
      ..write(obj.locationL1)
      ..writeByte(2)
      ..write(obj.locationL2)
      ..writeByte(3)
      ..write(obj.locationL3)
      ..writeByte(4)
      ..write(obj.light)
      ..writeByte(5)
      ..write(obj.temperature)
      ..writeByte(6)
      ..write(obj.humidity)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobMeasurementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

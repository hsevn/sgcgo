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
    return JobMeasurement()
      ..companyId = fields[0] as String?
      ..areaName = fields[1] as String?
      ..l1 = fields[2] as String?
      ..l2 = fields[3] as String?
      ..l3 = fields[4] as String?
      ..owasPhotoPath = fields[5] as String?
      ..postureNote = fields[6] as String?
      ..indicatorValues = (fields[7] as Map?)?.cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, JobMeasurement obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.companyId)
      ..writeByte(1)
      ..write(obj.areaName)
      ..writeByte(2)
      ..write(obj.l1)
      ..writeByte(3)
      ..write(obj.l2)
      ..writeByte(4)
      ..write(obj.l3)
      ..writeByte(5)
      ..write(obj.owasPhotoPath)
      ..writeByte(6)
      ..write(obj.postureNote)
      ..writeByte(7)
      ..write(obj.indicatorValues);
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

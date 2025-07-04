// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driving_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrivingSessionAdapter extends TypeAdapter<DrivingSession> {
  @override
  final int typeId = 1;

  @override
  DrivingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrivingSession(
      id: fields[0] as String,
      driverId: fields[1] as String,
      duration: fields[2] as Duration,
      date: fields[3] as DateTime,
      location: fields[4] as String,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DrivingSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.driverId)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrivingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

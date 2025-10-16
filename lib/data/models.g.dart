// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HeartRateDataAdapter extends TypeAdapter<HeartRateData> {
  @override
  final int typeId = 0;

  @override
  HeartRateData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeartRateData(
      heartRate: fields[0] as int,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HeartRateData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.heartRate)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class Spo2DataAdapter extends TypeAdapter<Spo2Data> {
  @override
  final int typeId = 1;

  @override
  Spo2Data read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Spo2Data(
      spo2: fields[0] as int,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Spo2Data obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.spo2)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Spo2DataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmSettingsAdapter extends TypeAdapter<AlarmSettings> {
  @override
  final int typeId = 2;

  @override
  AlarmSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmSettings(
      hrMin: fields[0] as int,
      hrMax: fields[1] as int,
      spo2Min: fields[2] as int,
      isHrAlarmEnabled: fields[3] as bool,
      isSpo2AlarmEnabled: fields[4] as bool,
      hrAlarmIntervalSeconds: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hrMin)
      ..writeByte(1)
      ..write(obj.hrMax)
      ..writeByte(2)
      ..write(obj.spo2Min)
      ..writeByte(3)
      ..write(obj.isHrAlarmEnabled)
      ..writeByte(4)
      ..write(obj.isSpo2AlarmEnabled)
      ..writeByte(5)
      ..write(obj.hrAlarmIntervalSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmHistoryAdapter extends TypeAdapter<AlarmHistory> {
  @override
  final int typeId = 3;

  @override
  AlarmHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmHistory(
      type: fields[0] as String,
      value: fields[1] as int,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmHistory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

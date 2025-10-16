import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
class HeartRateData extends HiveObject {
  @HiveField(0)
  late int heartRate;

  @HiveField(1)
  late DateTime timestamp;

  HeartRateData({required this.heartRate, required this.timestamp});
}

@HiveType(typeId: 1)
class Spo2Data extends HiveObject {
  @HiveField(0)
  late int spo2;

  @HiveField(1)
  late DateTime timestamp;

  Spo2Data({required this.spo2, required this.timestamp});
}

@HiveType(typeId: 2)
class AlarmSettings extends HiveObject {
  @HiveField(0)
  int hrMin;

  @HiveField(1)
  int hrMax;

  @HiveField(2)
  int spo2Min;

  @HiveField(3)
  bool isHrAlarmEnabled;

  @HiveField(4)
  bool isSpo2AlarmEnabled;

  @HiveField(5)
  int hrAlarmIntervalSeconds;

  AlarmSettings({
    this.hrMin = 50,
    this.hrMax = 100,
    this.spo2Min = 90,
    this.isHrAlarmEnabled = false,
    this.isSpo2AlarmEnabled = false,
    this.hrAlarmIntervalSeconds = 10,
  });

  Map<String, dynamic> toJson() => {
        'hrMin': hrMin,
        'hrMax': hrMax,
        'spo2Min': spo2Min,
        'isHrAlarmEnabled': isHrAlarmEnabled,
        'isSpo2AlarmEnabled': isSpo2AlarmEnabled,
        'hrAlarmIntervalSeconds': hrAlarmIntervalSeconds,
      };

  factory AlarmSettings.fromJson(Map<String, dynamic> json) => AlarmSettings(
        hrMin: json['hrMin'] ?? 50,
        hrMax: json['hrMax'] ?? 100,
        spo2Min: json['spo2Min'] ?? 90,
        isHrAlarmEnabled: json['isHrAlarmEnabled'] ?? false,
        isSpo2AlarmEnabled: json['isSpo2AlarmEnabled'] ?? false,
        hrAlarmIntervalSeconds: json['hrAlarmIntervalSeconds'] ?? 10,
      );
}

@HiveType(typeId: 3)
class AlarmHistory extends HiveObject {
  @HiveField(0)
  final String type;

  @HiveField(1)
  final int value;

  @HiveField(2)
  final DateTime timestamp;

  AlarmHistory({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'timestamp': timestamp,
      };

  factory AlarmHistory.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AlarmHistory(
      type: data['type'],
      value: data['value'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  factory AlarmHistory.fromJson(Map<String, dynamic> json) {
    return AlarmHistory(
      type: json['type'],
      value: json['value'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}

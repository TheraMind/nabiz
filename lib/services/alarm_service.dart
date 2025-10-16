import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kalp_atisi_app/data/models.dart';

class AlarmService {
  final AppBluetoothService _bluetoothService;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  StreamSubscription? _heartRateSubscription;
  StreamSubscription? _spo2Subscription;

  // Timers for delay-based alarms
  Timer? _hrAlarmTimer;
  Timer? _spo2AlarmTimer;
  int _latestHr = 0;
  int _latestSpo2 = 0;

  late Box<AlarmSettings> _alarmSettingsBox;
  late AlarmSettings _settings;

  final StreamController<AlarmSettings> _settingsController = StreamController<AlarmSettings>.broadcast();
  Stream<AlarmSettings> get settingsStream => _settingsController.stream;

  AlarmService(this._bluetoothService, this._flutterLocalNotificationsPlugin) {
    _initialize();
  }

  Future<void> _initialize() async {
    _alarmSettingsBox = await Hive.openBox<AlarmSettings>('alarmSettingsBox');
    await _loadAlarmSettings();
    _listenToDataStreams();
  }

  Future<void> _loadAlarmSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _settings = _alarmSettingsBox.get('default') ?? AlarmSettings();
      _settingsController.add(_settings);
      return;
    }

    // Try loading from Firestore first
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('alarms').get();
      if (doc.exists) {
        _settings = AlarmSettings.fromJson(doc.data()!);
        await _alarmSettingsBox.put(user.uid, _settings); // Update local cache
      } else {
        // If not in Firestore, try local cache
        _settings = _alarmSettingsBox.get(user.uid) ?? AlarmSettings();
      }
    } catch (e) {
      debugPrint("Error loading settings from Firestore: $e");
      // Fallback to local cache on error
      _settings = _alarmSettingsBox.get(user.uid) ?? AlarmSettings();
    }

    _settingsController.add(_settings);
  }

  Future<void> saveAlarmSettings(AlarmSettings newSettings) async {
    _settings = newSettings;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _alarmSettingsBox.put(user.uid, newSettings);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('alarms').set(newSettings.toJson());
      } catch (e) {
        debugPrint("Error saving settings to Firestore: $e");
      }
    } else {
      // Save for non-logged-in user
      await _alarmSettingsBox.put('default', newSettings);
    }
    _settingsController.add(newSettings);
  }

  void _listenToDataStreams() {
    _heartRateSubscription = _bluetoothService.heartRateStream.listen((hr) {
      if (_settings.isHrAlarmEnabled) {
        _checkHeartRateAlarm(hr);
      }
    });

    _spo2Subscription = _bluetoothService.spo2Stream.listen((spo2) {
      if (_settings.isSpo2AlarmEnabled) {
        _checkSpo2Alarm(spo2);
      }
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Bildirimleri',
      channelDescription: 'Uygulama alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'alarm_payload',
    );
  }

  void _checkHeartRateAlarm(int hr, {bool isTest = false}) {
    _latestHr = hr;

    if (!isTest && hr == 0) {
      _hrAlarmTimer?.cancel();
      _hrAlarmTimer = null;
      return;
    }

    final bool outOfRange = hr < _settings.hrMin || hr > _settings.hrMax;

    if (isTest) {
      if (outOfRange) {
        _sendHrNotification();
      }
      return;
    }

    if (outOfRange) {
      if (_hrAlarmTimer == null) {
        _sendHrNotification();
        _hrAlarmTimer = Timer.periodic(
          Duration(seconds: _settings.hrAlarmIntervalSeconds),
          (timer) {
            if (_latestHr < _settings.hrMin || _latestHr > _settings.hrMax) {
              _sendHrNotification();
            } else {
              timer.cancel();
              _hrAlarmTimer = null;
            }
          },
        );
      }
    } else {
      _hrAlarmTimer?.cancel();
      _hrAlarmTimer = null;
    }
  }

  void _checkSpo2Alarm(int spo2) {
    _latestSpo2 = spo2;

    if (spo2 == 0) {
      _spo2AlarmTimer?.cancel();
      _spo2AlarmTimer = null;
      return;
    }

    final bool belowMin = spo2 < _settings.spo2Min;

    if (belowMin) {
      _spo2AlarmTimer ??= Timer(Duration(seconds: _settings.hrAlarmIntervalSeconds), () {
        if (_latestSpo2 != 0 && _latestSpo2 < _settings.spo2Min) {
          _showNotification('SpO2 Alarmı', 'SpO2 çok düşük! ($_latestSpo2%)');
          _saveAlarmHistory('SpO2 Düşük', _latestSpo2);
        }
        _spo2AlarmTimer = null;
      });
    } else {
      _spo2AlarmTimer?.cancel();
      _spo2AlarmTimer = null;
    }
  }

  void _sendHrNotification() {
    if (_latestHr < _settings.hrMin) {
      _showNotification('Kalp Atışı Alarmı', 'Kalp atışı çok düşük! ($_latestHr bpm)');
      _saveAlarmHistory('Kalp Atışı Düşük', _latestHr);
    } else {
      _showNotification('Kalp Atışı Alarmı', 'Kalp atışı çok yüksek! ($_latestHr bpm)');
      _saveAlarmHistory('Kalp Atışı Yüksek', _latestHr);
    }
  }

  Future<void> _saveAlarmHistory(String type, int value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alarm = AlarmHistory(
      type: type,
      value: value,
      timestamp: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('alarm_history').add(alarm.toJson());
    } catch (e) {
      debugPrint("Alarm geçmişi Firestore'a kaydedilirken hata oluştu: $e");
    }
  }

  Future<void> sendTestNotification() async {
    await _showNotification(
      'Test Bildirimi',
      'Bildirimleriniz doğru şekilde çalışıyor.',
    );
  }

  void triggerTestHrAlarm() {
    debugPrint("Test kalp atış hızı alarmı tetikleniyor...");
    // Simulate a high heart rate to trigger the alarm logic, bypassing the connection check
    _checkHeartRateAlarm(150, isTest: true);
  }

  void dispose() {
    _heartRateSubscription?.cancel();
    _spo2Subscription?.cancel();
    _settingsController.close();
  }
}

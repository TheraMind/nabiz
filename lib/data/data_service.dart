import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kalp_atisi_app/data/models.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  static const String _heartRateBoxName = 'heartRateBox';
  static const String _spo2BoxName = 'spo2Box';
  static const String _alarmHistoryBoxName = 'alarmHistoryBox';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Box<HeartRateData>> get _heartRateBox async {
    try {
      return await Hive.openBox<HeartRateData>(_heartRateBoxName);
    } catch (e) {
      debugPrint('Error opening heart rate box: $e');
      rethrow;
    }
  }

  Future<Box<Spo2Data>> get _spo2Box async {
    try {
      return await Hive.openBox<Spo2Data>(_spo2BoxName);
    } catch (e) {
      debugPrint('Error opening spo2 box: $e');
      rethrow;
    }
  }

  Future<Box<AlarmHistory>> get _alarmHistoryBox async {
    try {
      return await Hive.openBox<AlarmHistory>(_alarmHistoryBoxName);
    } catch (e) {
      debugPrint('Error opening alarm history box: $e');
      rethrow;
    }
  }

  Future<void> addHeartRateData(HeartRateData data) async {
    try {
      final box = await _heartRateBox;
      await box.add(data);
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('heart_rate')
            .add({
          'heartRate': data.heartRate,
          'timestamp': data.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error adding heart rate data: $e');
    }
  }

  Future<void> addSpo2Data(Spo2Data data) async {
    try {
      final box = await _spo2Box;
      await box.add(data);
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('spo2')
            .add({
          'spo2': data.spo2,
          'timestamp': data.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error adding spo2 data: $e');
    }
  }

  Future<List<HeartRateData>> getHeartRateData() async {
    final box = await _heartRateBox;
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore.collection('users').doc(user.uid).collection('heart_rate').orderBy('timestamp').get();
        final data = snapshot.docs.map((doc) => HeartRateData(heartRate: doc['heartRate'], timestamp: (doc['timestamp'] as Timestamp).toDate())).toList();
        await box.clear();
        await box.addAll(data);
        return data;
      } catch (e) {
        debugPrint("Error fetching heart rate data from Firestore: $e");
        return box.values.toList(); // Return local data on error
      }
    }
    return box.values.toList();
  }

  Future<List<Spo2Data>> getSpo2Data() async {
    final box = await _spo2Box;
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore.collection('users').doc(user.uid).collection('spo2').orderBy('timestamp').get();
        final data = snapshot.docs.map((doc) => Spo2Data(spo2: doc['spo2'], timestamp: (doc['timestamp'] as Timestamp).toDate())).toList();
        await box.clear();
        await box.addAll(data);
        return data;
      } catch (e) {
        debugPrint("Error fetching spo2 data from Firestore: $e");
        return box.values.toList(); // Return local data on error
      }
    }
    return box.values.toList();
  }

  Future<List<AlarmHistory>> getAlarmHistory() async {
    final box = await _alarmHistoryBox;
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore.collection('users').doc(user.uid).collection('alarm_history').orderBy('timestamp', descending: true).get();
        final data = snapshot.docs.map((doc) => AlarmHistory.fromJson(doc.data())).toList();
        await box.clear();
        await box.addAll(data);
        return data;
      } catch (e) {
        debugPrint("Error fetching alarm history from Firestore: $e");
        return box.values.toList(); // Return local data on error
      }
    }
    return box.values.toList();
  }

  Future<void> syncLocalDataToCloud() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("Cannot sync, user not logged in.");
      return;
    }

    final hrBox = await _heartRateBox;
    final spo2Box = await _spo2Box;
    final alarmHistoryBox = await _alarmHistoryBox;

    if (hrBox.isEmpty && spo2Box.isEmpty && alarmHistoryBox.isEmpty) {
      debugPrint("No local data to sync.");
      return;
    }

    final batch = _firestore.batch();

    for (var data in hrBox.values) {
      final docRef = _firestore.collection('users').doc(user.uid).collection('heart_rate').doc();
      batch.set(docRef, {'heartRate': data.heartRate, 'timestamp': data.timestamp});
    }

    for (var data in spo2Box.values) {
      final docRef = _firestore.collection('users').doc(user.uid).collection('spo2').doc();
      batch.set(docRef, {'spo2': data.spo2, 'timestamp': data.timestamp});
    }

    for (var alarm in alarmHistoryBox.values) {
      final docRef = _firestore.collection('users').doc(user.uid).collection('alarm_history').doc();
      batch.set(docRef, alarm.toJson());
    }

    try {
      await batch.commit();
      debugPrint("Local data synced to cloud successfully.");
    } catch (e) {
      debugPrint("Error syncing local data to cloud: $e");
    }
  }

  Future<void> clearAllData() async {
    try {
      final hrBox = await _heartRateBox;
      await hrBox.clear();
      final spo2Box = await _spo2Box;
      await spo2Box.clear();
      final alarmHistoryBox = await _alarmHistoryBox;
      await alarmHistoryBox.clear();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }

  Future<void> generateMockData() async {
    try {
      final hrBox = await _heartRateBox;
      final spo2Box = await _spo2Box;

      if (hrBox.isNotEmpty || spo2Box.isNotEmpty) {
        return;
      }

      final random = Random();
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        for (int j = 0; j < 10; j++) {
          final timestamp = date.subtract(Duration(minutes: j * 60));
          hrBox.add(HeartRateData(heartRate: 60 + random.nextInt(40), timestamp: timestamp));
          spo2Box.add(Spo2Data(spo2: 90 + random.nextInt(10), timestamp: timestamp));
        }
      }

      for (int i = 0; i < 4; i++) {
        final date = now.subtract(Duration(days: i * 7));
        for (int j = 0; j < 5; j++) {
          final timestamp = date.subtract(Duration(hours: j * 24));
          hrBox.add(HeartRateData(heartRate: 60 + random.nextInt(40), timestamp: timestamp));
          spo2Box.add(Spo2Data(spo2: 90 + random.nextInt(10), timestamp: timestamp));
        }
      }

      for (int i = 0; i < 6; i++) {
        final date = DateTime(now.year, now.month - i, now.day);
        for (int j = 0; j < 3; j++) {
          final timestamp = date.subtract(Duration(days: j * 10));
          hrBox.add(HeartRateData(heartRate: 60 + random.nextInt(40), timestamp: timestamp));
          spo2Box.add(Spo2Data(spo2: 90 + random.nextInt(10), timestamp: timestamp));
        }
      }
    } catch (e) {
      debugPrint('Error generating mock data: $e');
    }
  }
}

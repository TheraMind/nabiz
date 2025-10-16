import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AppBluetoothService {
  // Using static methods directly for FlutterBluePlus
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _hrCharacteristicSubscription;
  StreamSubscription? _spo2CharacteristicSubscription;

  final StreamController<int> _heartRateController = StreamController<int>.broadcast();
  Stream<int> get heartRateStream => _heartRateController.stream;

  final StreamController<int> _spo2Controller = StreamController<int>.broadcast();
  Stream<int> get spo2Stream => _spo2Controller.stream;

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  final StreamController<List<ScanResult>> _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResultsStream => _scanResultsController.stream;

  AppBluetoothService() {
    _connectionStatusController.add(false); // Initial status
  }

  Future<void> startScan() async {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResultsController.add(results);
      });
    } else {
      debugPrint('Bluetooth tarama bu platformda desteklenmiyor.');
    }
  }

  Future<void> stopScan() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
    } else {
      debugPrint('Bluetooth tarama durdurma bu platformda desteklenmiyor.');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await stopScan(); // Yeni bir cihaza bağlanırken taramayı durdur
      _connectedDevice = device;
      _connectionStatusController.add(true); // Bağlantı denemesi sırasında bağlı olduğunu varsay
      _connectionSubscription = _connectedDevice?.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          _connectionStatusController.add(true);
          try {
            List<BluetoothService> services = await device.discoverServices();
            for (var service in services) {
              if (service.uuid.toString() == '12345678-1234-5678-1234-56789abcdef0') {
                for (var characteristic in service.characteristics) {
                  if (characteristic.uuid.toString() == 'abcdef01-1234-5678-1234-56789abcdef0') {
                    final success = await characteristic.setNotifyValue(true);
                    if(success) {
                      _hrCharacteristicSubscription = characteristic.lastValueStream.listen((value) {
                        print('HR verisi geldi (raw): $value');
                        if (value.isNotEmpty) {
                          // ESP32 sends a single byte for heart rate
                          final int heartRate = value[0];
                          print('İşlenmiş HR: $heartRate');
                          _heartRateController.add(heartRate);
                        }
                      });
                    }
                  } else if (characteristic.uuid.toString() == 'abcdef02-1234-5678-1234-56789abcdef0') {
                    final success = await characteristic.setNotifyValue(true);
                    if(success) {
                      _spo2CharacteristicSubscription = characteristic.lastValueStream.listen((value) {
                        print('SpO2 verisi geldi (raw): $value');
                        if (value.isNotEmpty) {
                          // ESP32 sends a single byte for SpO2
                          final int spo2 = value[0];
                          print('İşlenmiş SpO2: $spo2');
                          _spo2Controller.add(spo2);
                        }
                      });
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Hizmetler keşfedilirken hata oluştu: $e');
            disconnectDevice(); // Hata durumunda bağlantıyı kes
          }
        } else if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _connectionStatusController.add(false);
        }
      });
      await device.connect();
    } else {
      debugPrint('Bluetooth bağlantısı bu platformda desteklenmiyor.');
    }
  }

  Future<void> disconnectDevice() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _connectedDevice?.disconnect();
    } else {
      debugPrint('Bluetooth bağlantı kesme bu platformda desteklenmiyor.');
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _hrCharacteristicSubscription?.cancel();
    _spo2CharacteristicSubscription?.cancel();
    _heartRateController.close();
    _spo2Controller.close();
    _connectionStatusController.close();
  }
}
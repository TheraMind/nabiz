import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:kalp_atisi_app/screens/home_screen.dart';
import 'package:kalp_atisi_app/screens/history_screen.dart';
import 'package:kalp_atisi_app/screens/alarms_screen.dart';
import 'package:kalp_atisi_app/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;
  final AlarmService alarmService;
  final DataService dataService;

  const MainScreen({
    super.key,
    required this.bluetoothService,
    required this.alarmService,
    required this.dataService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(bluetoothService: widget.bluetoothService),
      HistoryScreen(dataService: widget.dataService),
      AlarmsScreen(alarmService: widget.alarmService),
      SettingsScreen(
        bluetoothService: widget.bluetoothService,
        alarmService: widget.alarmService,
        dataService: widget.dataService,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndServices();
    });
  }

  Future<void> _checkPermissionsAndServices() async {
    await _checkLocationService();
    await _checkBluetoothEnabled();

    if (mounted && !widget.bluetoothService.isConnected) {
      final snackBar = SnackBar(
        content: const Text('Bluetooth bağlı değil. Lütfen bir cihaz bağlayın.'),
        action: SnackBarAction(
          label: 'Ayarlar',
          onPressed: () {
            setState(() {
              _selectedIndex = 3;
            });
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _checkLocationService() async {
    final serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konum Servisi Kapalı'),
            content: const Text(
                'Bluetooth taraması için konum servisinin açık olması gerekmektedir.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _checkBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state == BluetoothAdapterState.off) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bluetooth Kapalı'),
          content: const Text(
              'Uygulamanın çalışabilmesi için Bluetooth özelliğini açmalısınız.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (Platform.isAndroid) {
                  await FlutterBluePlus.turnOn();
                }
              },
              child: const Text('Aç'),
            ),
          ],
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarmlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

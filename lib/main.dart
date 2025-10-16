import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kalp_atisi_app/data/models.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:kalp_atisi_app/screens/main_screen.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kalp_atisi_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kalp_atisi_app/screens/auth/login_screen.dart';
import 'package:kalp_atisi_app/screens/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:kalp_atisi_app/screens/home_screen.dart';
import 'package:kalp_atisi_app/screens/history_screen.dart';
import 'package:kalp_atisi_app/screens/alarms_screen.dart';
import 'package:kalp_atisi_app/screens/settings_screen.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    await Permission.location.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await _requestPermissions();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final initialUser = FirebaseAuth.instance.currentUser;

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

  await initializeDateFormatting('tr_TR', null);

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(HeartRateDataAdapter());
    Hive.registerAdapter(Spo2DataAdapter());
    Hive.registerAdapter(AlarmSettingsAdapter());
    Hive.registerAdapter(AlarmHistoryAdapter());
  } catch (e) {
    debugPrint('Hive initialization error: $e');
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const WindowsInitializationSettings initializationSettingsWindows =
      WindowsInitializationSettings(appName: 'Kalp Atisi App', appUserModelId: 'com.example.kalpatisiapp', guid: '{00000000-0000-0000-0000-000000000000}');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    windows: initializationSettingsWindows,
  );

  if (Platform.isAndroid || Platform.isWindows) {
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  runApp(MyApp(
    initialUser: initialUser,
  ));
}

class MyApp extends StatefulWidget {
  final User? initialUser;

  const MyApp({super.key, this.initialUser});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppBluetoothService _bluetoothService;
  late final DataService _dataService;
  late final AlarmService _alarmService;
  StreamSubscription? _hrSubscription;
  StreamSubscription? _spo2Subscription;

  @override
  void initState() {
    super.initState();
    _bluetoothService = AppBluetoothService();
    _dataService = DataService();
    _alarmService = AlarmService(_bluetoothService, flutterLocalNotificationsPlugin);
    _listenToDataStreams();
  }

  void _listenToDataStreams() {
    _hrSubscription = _bluetoothService.heartRateStream.listen((rate) {
      _dataService.addHeartRateData(HeartRateData(heartRate: rate, timestamp: DateTime.now()));
    });

    _spo2Subscription = _bluetoothService.spo2Stream.listen((level) {
      _dataService.addSpo2Data(Spo2Data(spo2: level, timestamp: DateTime.now()));
    });
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    _spo2Subscription?.cancel();
    _bluetoothService.dispose();
    _alarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalp Atışı İzleyici',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
      ),
      home: SplashScreen(
        nextScreen: widget.initialUser != null
            ? MainScreen(
                bluetoothService: _bluetoothService,
                alarmService: _alarmService,
                dataService: _dataService,
              )
            : LoginScreen(
                bluetoothService: _bluetoothService,
                alarmService: _alarmService,
                dataService: _dataService,
              ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;
  final AlarmService alarmService;
  final DataService dataService;

  const MainScreen({super.key, required this.bluetoothService, required this.alarmService, required this.dataService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndServices();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      HomeScreen(bluetoothService: widget.bluetoothService),
      HistoryScreen(dataService: widget.dataService),
      AlarmsScreen(alarmService: widget.alarmService),
      SettingsScreen(
        bluetoothService: widget.bluetoothService,
        alarmService: widget.alarmService,
        dataService: widget.dataService,
      ),
    ];

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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

  Future<void> _checkLocationService() async {
    final serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konum Servisi Kapalı'),
            content: const Text('Bluetooth taraması için konum servisinin açık olması gerekmektedir.'),
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
          content: const Text('Uygulamanın çalışabilmesi için Bluetooth özelliğini açmalısınız.'),
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
}

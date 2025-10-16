import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';

class HomeScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;

  const HomeScreen({super.key, required this.bluetoothService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _heartRate = 0;
  int _spo2 = 0;
  StreamSubscription? _hrSubscription;
  StreamSubscription? _spo2Subscription;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBluetooth();
  }

  void _listenToBluetooth() {
    _connectionSubscription = widget.bluetoothService.connectionStatusStream.listen((status) {
      if (mounted && !status) {
        setState(() {
          _heartRate = 0;
          _spo2 = 0;
        });
      }
    });

    _hrSubscription = widget.bluetoothService.heartRateStream.listen((rate) {
      if (mounted) {
        setState(() {
          _heartRate = rate;
        });
      }
    });

    _spo2Subscription = widget.bluetoothService.spo2Stream.listen((level) {
      if (mounted) {
        setState(() {
          _spo2 = level;
        });
      }
    });
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    _spo2Subscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ana Sayfa',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          StreamBuilder<bool>(
            stream: widget.bluetoothService.connectionStatusStream,
            initialData: false,
            builder: (c, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: isConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Anlık Kalp Atış Hızı',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_heartRate BPM',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Anlık SpO2',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_spo2 %',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

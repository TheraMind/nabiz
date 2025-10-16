import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;

  const BluetoothScreen({super.key, required this.bluetoothService});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _systemDevices = [];

  @override
  void initState() {
    super.initState();
    _listenToConnectionStatus();
    _getSystemDevices();
    widget.bluetoothService.startScan(); // Ekran açıldığında taramayı başlat
  }

  Future<void> _getSystemDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluePlus.systemDevices([Guid("12345678-1234-5678-1234-56789abcdef0")]);
      if (mounted) {
        setState(() {
          _systemDevices = devices;
        });
      }
    } catch (e) {
      print("Sistem cihazları alınamadı: $e");
    }
  }

  @override
  void dispose() {
    widget.bluetoothService.stopScan();
    super.dispose();
  }

  void _listenToConnectionStatus() {
    widget.bluetoothService.connectionStatusStream.listen((status) {
      if (mounted) { // Widget'ın hala ağaçta olduğundan emin ol
        setState(() {
          _connectedDevice = status ? widget.bluetoothService.connectedDevice : null;
        });
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await widget.bluetoothService.connectToDevice(device);
  }

  Future<void> _disconnectDevice() async {
    await widget.bluetoothService.disconnectDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bluetooth Cihazları',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          StreamBuilder<bool>(
            stream: FlutterBluePlus.isScanning,
            initialData: false,
            builder: (c, snapshot) {
              if (snapshot.data ?? false) {
                return IconButton(
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary), // Use primary color
                  ),
                  onPressed: () => widget.bluetoothService.stopScan(),
                );
              } else {
                return IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface), // Use onSurface color
                  onPressed: () => widget.bluetoothService.startScan(),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _connectedDevice != null
                ? Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.bluetooth_connected, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bağlı Cihaz',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                                Text(
                                  _connectedDevice!.platformName.isNotEmpty ? _connectedDevice!.platformName : 'Bilinmeyen Cihaz',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _disconnectDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Theme.of(context).colorScheme.onError,
                            ),
                            child: const Text('Kes'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(Icons.bluetooth_disabled, color: Theme.of(context).colorScheme.onTertiaryContainer, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cihaz Bağlı Değil',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onTertiaryContainer),
                                ),
                                Text(
                                  'Lütfen bir cihaz tarayın ve bağlanın.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: widget.bluetoothService.scanResultsStream,
              initialData: const [],
              builder: (c, snapshot) {
                final scanResults = snapshot.data ?? [];
                final allDevices = <BluetoothDevice>{..._systemDevices, ...scanResults.map((r) => r.device)}.toList();

                if (allDevices.isEmpty) {
                  return Center(
                    child: Text(
                      'Cihaz bulunamadı. Tekrar tarayın.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: allDevices.length,
                  itemBuilder: (context, index) {
                    final device = allDevices[index];
                    if (device.platformName.isEmpty) return const SizedBox.shrink();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: Icon(Icons.bluetooth, color: Theme.of(context).colorScheme.primary),
                        title: Text(
                          device.platformName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          device.remoteId.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Bağlan'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

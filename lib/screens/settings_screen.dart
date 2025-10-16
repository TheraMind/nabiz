import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:kalp_atisi_app/screens/alarm_history_screen.dart';
import 'package:kalp_atisi_app/screens/auth/login_screen.dart';
import 'package:kalp_atisi_app/screens/bluetooth_screen.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';

class SettingsScreen extends StatelessWidget {
  final AppBluetoothService bluetoothService;
  final AlarmService alarmService;
  final DataService dataService;

  const SettingsScreen({
    super.key,
    required this.bluetoothService,
    required this.alarmService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.bluetooth, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Bluetooth Ayarları',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BluetoothScreen(bluetoothService: bluetoothService),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Alarm Geçmişi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlarmHistoryScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Verileri Buluta Eşitle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veriler eşitleniyor...')),
                );
                try {
                  await dataService.syncLocalDataToCloud();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veriler başarıyla eşitlendi.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eşitleme başarısız: $e')),
                  );
                }
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Test Bildirimi Gönder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                alarmService.sendTestNotification();
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.add_alert, color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Test Alarmı Tetikle',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                alarmService.triggerTestHrAlarm();
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Çıkış Yap',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      bluetoothService: bluetoothService,
                      alarmService: alarmService,
                      dataService: dataService,
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

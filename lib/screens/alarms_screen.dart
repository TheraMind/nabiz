import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/data/models.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';

class AlarmsScreen extends StatefulWidget {
  final AlarmService alarmService;

  const AlarmsScreen({super.key, required this.alarmService});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  final TextEditingController _hrMinController = TextEditingController();
  final TextEditingController _hrMaxController = TextEditingController();
  final TextEditingController _spo2MinController = TextEditingController();
  final TextEditingController _hrIntervalController = TextEditingController();

  late StreamSubscription<AlarmSettings> _settingsSubscription;
  late AlarmSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = AlarmSettings(); // Start with default
    _settingsSubscription = widget.alarmService.settingsStream.listen((settings) {
      if (mounted) {
        setState(() {
          _currentSettings = settings;
          _hrMinController.text = settings.hrMin.toString();
          _hrMaxController.text = settings.hrMax.toString();
          _spo2MinController.text = settings.spo2Min.toString();
          _hrIntervalController.text = settings.hrAlarmIntervalSeconds.toString();
        });
      }
    });
  }

  Future<void> _saveAlarmSettings() async {
    final newSettings = AlarmSettings(
      hrMin: int.tryParse(_hrMinController.text) ?? _currentSettings.hrMin,
      hrMax: int.tryParse(_hrMaxController.text) ?? _currentSettings.hrMax,
      spo2Min: int.tryParse(_spo2MinController.text) ?? _currentSettings.spo2Min,
      isHrAlarmEnabled: _currentSettings.isHrAlarmEnabled,
      isSpo2AlarmEnabled: _currentSettings.isSpo2AlarmEnabled,
      hrAlarmIntervalSeconds: int.tryParse(_hrIntervalController.text) ?? _currentSettings.hrAlarmIntervalSeconds,
    );

    await widget.alarmService.saveAlarmSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm ayarları kaydedildi.')),
      );
    }
  }

  @override
  void dispose() {
    _hrMinController.dispose();
    _hrMaxController.dispose();
    _spo2MinController.dispose();
    _hrIntervalController.dispose();
    _settingsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alarm Ayarları',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAlarmCard(
              context: context,
              title: 'Kalp Atışı Alarmı',
              icon: Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
              isEnabled: _currentSettings.isHrAlarmEnabled,
              onToggle: (value) {
                setState(() {
                  _currentSettings.isHrAlarmEnabled = value;
                });
              },
              children: [
                TextFormField(
                  controller: _hrMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Kalp Atışı (bpm)',
                    prefixIcon: Icon(Icons.arrow_downward),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _hrMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maksimum Kalp Atışı (bpm)',
                    prefixIcon: Icon(Icons.arrow_upward),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _hrIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Tekrar Sıklığı (sn)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildAlarmCard(
              context: context,
              title: 'SpO2 Alarmı',
              icon: Icons.water_drop,
              color: Theme.of(context).colorScheme.secondary,
              isEnabled: _currentSettings.isSpo2AlarmEnabled,
              onToggle: (value) {
                setState(() {
                  _currentSettings.isSpo2AlarmEnabled = value;
                });
              },
              children: [
                TextFormField(
                  controller: _spo2MinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum SpO2 (%)',
                    prefixIcon: Icon(Icons.arrow_downward),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveAlarmSettings,
              icon: const Icon(Icons.save),
              label: const Text('Ayarları Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 30),
                    const SizedBox(width: 15),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 20),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

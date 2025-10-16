import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:kalp_atisi_app/data/models.dart';

class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({super.key});

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  final DataService _dataService = DataService();
  late Future<List<AlarmHistory>> _alarmHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadAlarmHistory();
  }

  void _loadAlarmHistory() {
    setState(() {
      _alarmHistoryFuture = _dataService.getAlarmHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Geçmişi'),
      ),
      body: FutureBuilder<List<AlarmHistory>>(
        future: _alarmHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz bir alarm tetiklenmemiş.'),
            );
          }

          final alarmHistory = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadAlarmHistory();
            },
            child: ListView.builder(
              itemCount: alarmHistory.length,
              itemBuilder: (context, index) {
                final alarm = alarmHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: Icon(
                      alarm.type.contains('Kalp') ? Icons.favorite : Icons.air,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(alarm.type),
                    subtitle: Text('Değer: ${alarm.value}'),
                    trailing: Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(alarm.timestamp),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

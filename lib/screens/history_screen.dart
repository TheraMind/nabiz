import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:kalp_atisi_app/data/models.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

class HistoryScreen extends StatefulWidget {
  final DataService dataService;

  const HistoryScreen({super.key, required this.dataService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  List<HeartRateData> _hrData = [];
  List<Spo2Data> _spo2Data = [];

  DateTime _currentDate = DateTime.now(); // New: Track current date for navigation

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentDate = DateTime.now(); // Reset date when tab changes
        });
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final hrData = await widget.dataService.getHeartRateData();
    final spo2Data = await widget.dataService.getSpo2Data();
    setState(() {
      _hrData = hrData;
      _spo2Data = spo2Data;
    });
  }

  void _goToPreviousPeriod() {
    setState(() {
      if (_tabController.index == 0) { // Daily
        _currentDate = _currentDate.subtract(const Duration(days: 1));
      } else if (_tabController.index == 1) { // Weekly
        _currentDate = _currentDate.subtract(const Duration(days: 7));
      } else if (_tabController.index == 2) { // Monthly
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
      }
    });
    _loadData();
  }

  void _goToNextPeriod() {
    setState(() {
      if (_tabController.index == 0) { // Daily
        _currentDate = _currentDate.add(const Duration(days: 1));
      } else if (_tabController.index == 1) { // Weekly
        _currentDate = _currentDate.add(const Duration(days: 7));
      } else if (_tabController.index == 2) { // Monthly
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
      }
    });
    _loadData();
  }

  String _getDateRangeText() {
    final currentTab = _tabController.index;
    if (currentTab == 0) { // Daily
      return DateFormat('dd MMMM yyyy EEEE', 'tr_TR').format(_currentDate);
    } else if (currentTab == 1) { // Weekly
      DateTime startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('dd MMM', 'tr_TR').format(startOfWeek)} - ${DateFormat('dd MMM yyyy', 'tr_TR').format(endOfWeek)}';
    } else { // Monthly
      return DateFormat('MMMM yyyy', 'tr_TR').format(_currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _goToPreviousPeriod,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Geçmiş Veriler',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4), // Small space between title and date range
                Text(
                  _getDateRangeText(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _goToNextPeriod,
            ),
          ],
        ),
        centerTitle: true, // Center the title column
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary, // Primary color for indicator
          labelColor: Theme.of(context).colorScheme.primary, // Primary color for selected label
          unselectedLabelColor: Colors.grey.shade600, // Grey for unselected labels
          labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold selected label
          tabs: const [
            Tab(text: 'Günlük'),
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildChart('Günlük', _hrData, _spo2Data),
            _buildChart('Haftalık', _hrData, _spo2Data),
            _buildChart('Aylık', _hrData, _spo2Data),
          ],
        ),
      ),
    );
  }

  Map<DateTime, double> _aggregateDailyData<T>(List<T> data, DateTime Function(T) getTime, double Function(T) getValue) {
    final Map<DateTime, List<double>> dailyValues = {};

    for (var item in data) {
      final date = DateTime(getTime(item).year, getTime(item).month, getTime(item).day);
      if (!dailyValues.containsKey(date)) {
        dailyValues[date] = [];
      }
      dailyValues[date]!.add(getValue(item));
    }

    final Map<DateTime, double> aggregatedData = {};
    dailyValues.forEach((date, values) {
      aggregatedData[date] = values.reduce((a, b) => a + b) / values.length;
    });
    return aggregatedData;
  }

  Widget _buildChart(String period, List<HeartRateData> hrData, List<Spo2Data> spo2Data) {
    List<HeartRateData> filteredHrData = [];
    List<Spo2Data> filteredSpo2Data = [];

    Map<DateTime, double> aggregatedHrData = {};
    Map<DateTime, double> aggregatedSpo2Data = {};

    DateTime displayDate = _currentDate;

    if (period == 'Günlük') {
      filteredHrData = hrData.where((d) => d.timestamp.day == displayDate.day && d.timestamp.month == displayDate.month && d.timestamp.year == displayDate.year).toList();
      filteredSpo2Data = spo2Data.where((d) => d.timestamp.day == displayDate.day && d.timestamp.month == displayDate.month && d.timestamp.year == displayDate.year).toList();
    } else if (period == 'Haftalık') {
      DateTime startOfWeek = displayDate.subtract(Duration(days: displayDate.weekday - 1));
      filteredHrData = hrData.where((d) => d.timestamp.isAfter(startOfWeek.subtract(const Duration(days: 1))) && d.timestamp.isBefore(startOfWeek.add(const Duration(days: 7)))).toList();
      filteredSpo2Data = spo2Data.where((d) => d.timestamp.isAfter(startOfWeek.subtract(const Duration(days: 1))) && d.timestamp.isBefore(startOfWeek.add(const Duration(days: 7)))).toList();

      aggregatedHrData = _aggregateDailyData(filteredHrData, (data) => data.timestamp, (data) => data.heartRate.toDouble());
      aggregatedSpo2Data = _aggregateDailyData(filteredSpo2Data, (data) => data.timestamp, (data) => data.spo2.toDouble());
    } else if (period == 'Aylık') {
      filteredHrData = hrData.where((d) => d.timestamp.month == displayDate.month && d.timestamp.year == displayDate.year).toList();
      filteredSpo2Data = spo2Data.where((d) => d.timestamp.month == displayDate.month && d.timestamp.year == displayDate.year).toList();

      aggregatedHrData = _aggregateDailyData(filteredHrData, (data) => data.timestamp, (data) => data.heartRate.toDouble());
      aggregatedSpo2Data = _aggregateDailyData(filteredSpo2Data, (data) => data.timestamp, (data) => data.spo2.toDouble());
    }

    if (filteredHrData.isEmpty && filteredSpo2Data.isEmpty && aggregatedHrData.isEmpty && aggregatedSpo2Data.isEmpty) {
      return Center(
        child: Text(
          'Bu dönem için veri bulunmamaktadır.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    List<FlSpot> hrSpots = [];
    List<FlSpot> spo2Spots = [];

    if (period == 'Günlük') {
      hrSpots = filteredHrData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.heartRate.toDouble());
      }).toList();

      spo2Spots = filteredSpo2Data.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.spo2.toDouble());
      }).toList();
    } else {
      // Haftalık ve Aylık için toplanmış verileri kullan
      hrSpots = aggregatedHrData.entries.map((entry) {
        return FlSpot(entry.key.day.toDouble(), entry.value);
      }).toList();
      hrSpots.sort((a, b) => a.x.compareTo(b.x)); // Tarihe göre sırala

      spo2Spots = aggregatedSpo2Data.entries.map((entry) {
        return FlSpot(entry.key.day.toDouble(), entry.value);
      }).toList();
      spo2Spots.sort((a, b) => a.x.compareTo(b.x)); // Tarihe göre sırala
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (hrSpots.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kalp Atış Hızı Grafiği',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: period == 'Günlük' ? (filteredHrData.length / 5).ceil().toDouble() : 1,
                                getTitlesWidget: (value, meta) {
                                  if (period == 'Günlük') {
                                    if (value.toInt() < filteredHrData.length) {
                                      return Text(DateFormat('HH:mm').format(filteredHrData[value.toInt()].timestamp), style: const TextStyle(fontSize: 10));
                                    }
                                  } else if (period == 'Haftalık') {
                                    // Haftalık görünümde günleri göster
                                    final date = DateTime(displayDate.year, displayDate.month, value.toInt());
                                    return Text(DateFormat('EEE').format(date), style: const TextStyle(fontSize: 10));
                                  } else if (period == 'Aylık') {
                                    // Aylık görünümde günleri göster
                                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 10, // Adjust interval for better readability
                                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false), // Remove border, grid lines are enough
                          lineBarsData: [
                            LineChartBarData(
                              spots: hrSpots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: hrSpots.length < 10), // Show dots only if data points are few
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    Theme.of(context).colorScheme.primary.withOpacity(0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (spo2Spots.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SpO2 Grafiği',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: period == 'Günlük' ? (filteredSpo2Data.length / 5).ceil().toDouble() : 1,
                                getTitlesWidget: (value, meta) {
                                  if (period == 'Günlük') {
                                    if (value.toInt() < filteredSpo2Data.length) {
                                      return Text(DateFormat('HH:mm').format(filteredSpo2Data[value.toInt()].timestamp), style: const TextStyle(fontSize: 10));
                                    }
                                  } else if (period == 'Haftalık') {
                                    // Haftalık görünümde günleri göster
                                    final date = DateTime(displayDate.year, displayDate.month, value.toInt());
                                    return Text(DateFormat('EEE').format(date), style: const TextStyle(fontSize: 10));
                                  } else if (period == 'Aylık') {
                                    // Aylık görünümde günleri göster
                                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 10, // Adjust interval for better readability
                                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false), // Remove border, grid lines are enough
                          lineBarsData: [
                            LineChartBarData(
                              spots: spo2Spots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.secondary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: spo2Spots.length < 10), // Show dots only if data points are few
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

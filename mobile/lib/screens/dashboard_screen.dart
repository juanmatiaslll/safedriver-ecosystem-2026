import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  bool _loading = true;

  int _activeDrivers = 0;
  int _todayAlerts = 0;
  Map<String, dynamic>? _topDriver;
  List<int> _alertsByHour = List<int>.filled(24, 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadStats());
  }

  Future<void> _loadStats() async {
    final data = await _apiService.getDashboardStats();
    if (data == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _activeDrivers = data['active_drivers'] ?? 0;
      _todayAlerts = data['today_alerts'] ?? 0;
      _topDriver = data['top_driver'];
      final raw = data['alerts_by_hour'] as List?;
      if (raw != null) {
        _alertsByHour = raw.cast<int>();
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiRow(),
                  const SizedBox(height: 24),
                  const Text(
                    "Alertas por hora",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: _buildBarChart(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              Expanded(child: _kpiCard("Conductores en ruta", _activeDrivers.toString(), Icons.person, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard("Alertas hoy", _todayAlerts.toString(), Icons.warning, Colors.red)),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiCard(
                  "Top conductor",
                  _topDriver != null ? "${_topDriver!['name']} (${_topDriver!['alert_count']})" : "N/A",
                  Icons.person,
                  Colors.orange,
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _kpiCard("Conductores en ruta", _activeDrivers.toString(), Icons.person, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _kpiCard("Alertas hoy", _todayAlerts.toString(), Icons.warning, Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            _kpiCard(
              "Conductor con más alertas",
              _topDriver != null ? "${_topDriver!['name']} (${_topDriver!['alert_count']})" : "N/A",
              Icons.person,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxY = _alertsByHour.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final hours = [0, 6, 12, 18, 23];
                if (hours.contains(value.toInt())) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        barGroups: List.generate(24, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _alertsByHour[i].toDouble(),
                color: Colors.red,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

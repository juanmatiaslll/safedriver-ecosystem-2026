import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
  List<Map<String, dynamic>> _alertsByDriver = [];

  static const _driverColors = [
    SafeDriverTheme.accent,
    SafeDriverTheme.primary,
    Color(0xFFE65100),
    Color(0xFF7B1FA2),
    Color(0xFF00897B),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadStats());
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
      final driverRaw = data['alerts_by_driver'] as List?;
      if (driverRaw != null) {
        _alertsByDriver = driverRaw.cast<Map<String, dynamic>>();
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
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiRow(),
                const SizedBox(height: 24),
                _buildDriverChartSection(),
              ],
            ),
          );
  }

  Widget _buildKpiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _kpiCard("En ruta", _activeDrivers.toString(), Icons.person, SafeDriverTheme.accent)),
          const SizedBox(width: 8),
          Expanded(child: _kpiCard("Alertas hoy", _todayAlerts.toString(), Icons.warning, SafeDriverTheme.alta)),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: SafeDriverTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SafeDriverTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alertas por conductor (hoy)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SafeDriverTheme.textPrimary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _buildDriverBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverBarChart() {
    if (_alertsByDriver.isEmpty) {
      return Center(
        child: Text("Sin datos", style: TextStyle(fontSize: 14, color: SafeDriverTheme.textSecondary)),
      );
    }
    final maxVal = _alertsByDriver
        .map((d) => (d['alert_count'] as int?) ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxVal.toDouble().clamp(1.0, double.infinity);
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
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < _alertsByDriver.length) {
                  final name = _alertsByDriver[idx]['driver_name'] as String? ?? '';
                  final count = _alertsByDriver[idx]['alert_count'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "$name\n$count alertas",
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString(), style: const TextStyle(fontSize: 11)),
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
          getDrawingHorizontalLine: (value) => FlLine(
            color: SafeDriverTheme.surface,
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(_alertsByDriver.length, (i) {
          final count = (_alertsByDriver[i]['alert_count'] as int?) ?? 0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: _driverColors[i % _driverColors.length],
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

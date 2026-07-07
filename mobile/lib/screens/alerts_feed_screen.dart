import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import '../theme.dart';

class AlertsFeedScreen extends StatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  State<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends State<AlertsFeedScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<AlertModel> _alerts = [];
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAlerts());
  }

  Future<void> _loadAlerts() async {
    final result = await _apiService.getAlerts(todayOnly: true);
    if (!mounted) return;
    setState(() {
      _alerts = (result?['alerts'] as List<AlertModel>?) ?? [];
      _total = (result?['total'] as int?) ?? 0;
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            "Alertas activas: $_total",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SafeDriverTheme.textSecondary,
            ),
          ),
        ),
        if (_alerts.isEmpty)
          Expanded(
            child: Center(
              child: Text("Sin alertas activas",
                  style: TextStyle(fontSize: 15, color: SafeDriverTheme.textSecondary)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _alerts.length,
              itemBuilder: (context, i) => AlertCard(
                alert: _alerts[i],
              ),
            ),
          ),
      ],
    );
  }
}

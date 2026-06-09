import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';

class AlertsFeedScreen extends StatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  State<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends State<AlertsFeedScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAlerts());
  }

  Future<void> _loadAlerts() async {
    final alerts = await _apiService.getAlerts(todayOnly: true);
    if (!mounted) return;
    setState(() {
      _alerts = alerts ?? [];
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
      appBar: AppBar(title: const Text("Alertas")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, i) => AlertCard(
                alert: _alerts[i],
                onResolve: () async {
                  await _apiService.resolveAlert(_alerts[i].id);
                  _loadAlerts();
                },
              ),
            ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  List<AlertModel> _alerts = [];
  Map<String, dynamic>? _telemetry;
  Timer? _telemetryTimer;

  Future<void> _logout() async {
    await _apiService.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _loadTelemetry();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadTelemetry());
  }

  Future<void> _loadTelemetry() async {
    final driverId = await _apiService.getDriverIdFromToken();
    if (driverId == null) return;
    final t = await _apiService.getLatestTelemetry(driverId);
    if (!mounted) return;
    setState(() => _telemetry = t);
  }

  Future<void> _loadAlerts() async {
    final driverId = await _apiService.getDriverIdFromToken();
    final alerts = await _apiService.getAlerts();

    if (driverId == null || alerts == null) {
      setState(() => _loading = false);
      return;
    }

    final today = DateTime.now();
    final filteredAlerts = alerts.where((alert) {
      if (alert.driverId != driverId || alert.createdAt == null) return false;
      final date = alert.createdAt!.toLocal();
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }).toList();

    filteredAlerts.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    setState(() {
      _alerts = filteredAlerts;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  // CORRECCIÓN: Ahora recibe DateTime? en lugar de String?
  String _formatTime(DateTime? date) {
    if (date == null) return "--:--";
    // Ajuste de zona horaria si es necesario (-5 horas)
    final adjustedDate = date.subtract(const Duration(hours: 5));
    return "${adjustedDate.hour.toString().padLeft(2, '0')}:${adjustedDate.minute.toString().padLeft(2, '0')}";
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType.toUpperCase()) {
      case "FATIGA": return Icons.bedtime;
      case "DISTRACCION": return Icons.visibility;
      case "VELOCIDAD": return Icons.speed;
      default: return Icons.warning_amber_rounded;
    }
  }

  String _getAlertLabel(String alertType) {
    switch (alertType.toUpperCase()) {
      case "FATIGA": return "Fatiga";
      case "DISTRACCION": return "Distracción";
      case "VELOCIDAD": return "Exceso de Velocidad";
      default: return alertType;
    }
  }

  String _statusText(double fatigue, double speed) {
    if (fatigue > 80) return "PELIGRO - Fatiga crítica";
    if (speed > 120) return "PELIGRO - Velocidad excesiva";
    if (fatigue > 60) return "PRECAUCIÓN - Fatiga elevada";
    if (speed > 100) return "PRECAUCIÓN - Velocidad elevada";
    return "CONDUCCIÓN SEGURA";
  }

  Color _statusColor(double fatigue, double speed) {
    if (fatigue > 80 || speed > 120) return Colors.red;
    if (fatigue > 60 || speed > 100) return Colors.orange;
    return Colors.green;
  }

  Widget _buildTelemetryPanel() {
    if (_telemetry == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.grey.shade100,
        child: const Text("Esperando datos del sensor...", style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }
    final fatigue = (_telemetry!['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry!['speed'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(fatigue, speed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: color.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_statusText(fatigue, speed), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(width: 90, child: Text("FATIGA", style: TextStyle(fontSize: 15, color: Colors.grey.shade600))),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: fatigue / 100, color: color, minHeight: 16))),
              const SizedBox(width: 12),
              Text("${fatigue.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _alerts.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Alertas"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          _buildTelemetryPanel(),
          Expanded(
            child: !hasAlerts ? const Center(child: Text("Sin alertas activas")) : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  color: severityToColor(alert.severity),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(_getAlertIcon(alert.alertType), color: Colors.white, size: 40),
                    title: Text(_getAlertLabel(alert.alertType), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Severidad: ${alert.severity}", style: const TextStyle(color: Colors.white)),
                        Text("Hora: ${_formatTime(alert.createdAt)}", style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
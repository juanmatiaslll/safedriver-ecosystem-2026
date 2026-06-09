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

  String _driverName = "";
  String _driverDni = "";

  Future<void> _logout() async {
    await _apiService.clearToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();

    _loadDriverInfo();
    _loadAlerts();
    _loadTelemetry();

    _telemetryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _loadTelemetry();
        _loadAlerts();
      },
    );
  }

  Future<void> _loadDriverInfo() async {
    final driverId = await _apiService.getDriverIdFromToken();

    if (driverId == null) return;

    final drivers = await _apiService.getDrivers();

    try {
      final driver = drivers.firstWhere(
        (d) => d.id == driverId,
      );

      if (!mounted) return;

      setState(() {
        _driverName = driver.name;
        _driverDni = driver.dni;
      });
    } catch (_) {}
  }

  Future<void> _loadTelemetry() async {
    final driverId = await _apiService.getDriverIdFromToken();

    if (driverId == null) return;

    final telemetry = await _apiService.getLatestTelemetry(driverId);

    if (!mounted) return;

    setState(() {
      _telemetry = telemetry;
    });
  }

  Future<void> _loadAlerts() async {
    final driverId = await _apiService.getDriverIdFromToken();
    final alerts = await _apiService.getAlerts();

    if (driverId == null || alerts == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final today = DateTime.now();

    final filteredAlerts = alerts.where((alert) {
      if (alert.driverId != driverId) {
        return false;
      }

      if (alert.createdAt == null) {
        return false;
      }

      final alertDate = DateTime.parse(alert.createdAt!).toLocal();

      return alertDate.year == today.year &&
          alertDate.month == today.month &&
          alertDate.day == today.day;
    }).toList();

    filteredAlerts.sort((a, b) {
      final dateA = DateTime.parse(a.createdAt!).toLocal();
      final dateB = DateTime.parse(b.createdAt!).toLocal();

      return dateB.compareTo(dateA);
    });

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

  String _formatTime(String? createdAt) {
    if (createdAt == null) {
      return "--:--";
    }

    final date = DateTime.parse(createdAt).subtract(
      const Duration(hours: 5),
    );

    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType.toUpperCase()) {
      case "FATIGA":
        return Icons.bedtime;

      case "DISTRACCION":
        return Icons.visibility;

      case "VELOCIDAD":
        return Icons.speed;

      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _getAlertLabel(String alertType) {
    switch (alertType.toUpperCase()) {
      case "FATIGA":
        return "Fatiga";

      case "DISTRACCION":
        return "Distracción";

      case "VELOCIDAD":
        return "Exceso de Velocidad";

      default:
        return alertType;
    }
  }

  String _statusText(double fatigue, double speed) {
    if (fatigue > 80) return "PELIGRO - Fatiga critica";
    if (speed > 120) return "PELIGRO - Velocidad excesiva";
    if (fatigue > 60) return "PRECAUCION - Fatiga elevada";
    if (speed > 100) return "PRECAUCION - Velocidad elevada";
    return "CONDUCCION SEGURA";
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
        child: const Text("Esperando datos del sensor...",
            style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }
    final fatigue = (_telemetry!['fatigue_level'] as num?)?.toDouble() ?? 0;
    final heart = (_telemetry!['heart_rate'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry!['speed'] as num?)?.toDouble() ?? 0;
    final status = _statusText(fatigue, speed);
    final color = _statusColor(fatigue, speed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: color.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text("FATIGA",
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fatigue / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: color,
                    minHeight: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text("${fatigue.toStringAsFixed(0)}%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text("RITMO",
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade600)),
              ),
              Text("${heart.toStringAsFixed(0)} BPM",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text("VELOCIDAD",
                    style:
                        TextStyle(fontSize: 15, color: Colors.grey.shade600)),
              ),
              Text("${speed.toStringAsFixed(0)} km/h",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: speed > 120
                          ? Colors.red
                          : speed > 100
                              ? Colors.orange
                              : Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSafe(double fatigue, double speed) {
    return fatigue <= 60 && speed <= 100;
  }

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _alerts.isNotEmpty;
    final fatigue = (_telemetry?['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry?['speed'] as num?)?.toDouble() ?? 0;
    final isGreen = _isSafe(fatigue, speed);

    Color backgroundColor;
    if (fatigue > 80 || speed > 120) {
      backgroundColor = Colors.red.shade50;
    } else if (fatigue > 60 || speed > 100) {
      backgroundColor = Colors.orange.shade50;
    } else if (hasAlerts) {
      backgroundColor =
          severityToColor(_alerts.first.severity).withOpacity(0.15);
    } else {
      backgroundColor = Colors.green.shade50;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Mis Alertas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Hola, $_driverName - DNI: $_driverDni",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildTelemetryPanel(),
                Expanded(
                  child: !hasAlerts && isGreen
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 120,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Sin alertas activas",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];

                            return Card(
                              color: severityToColor(alert.severity),
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 6,
                              child: ListTile(
                                leading: Icon(
                                  _getAlertIcon(alert.alertType),
                                  color: Colors.white,
                                  size: 40,
                                ),
                                title: Text(
                                  _getAlertLabel(alert.alertType),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      "Severidad: ${alert.severity}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Hora: ${_formatTime(alert.createdAt)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
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

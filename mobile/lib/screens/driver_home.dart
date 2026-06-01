import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';
import '../utils/colors.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  List<AlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
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

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _alerts.isNotEmpty;

    Color backgroundColor = Colors.green.shade100;

    if (hasAlerts) {
      backgroundColor =
          severityToColor(_alerts.first.severity).withOpacity(0.35);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Mis Alertas"),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : hasAlerts
              ? ListView.builder(
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
                )
              : Center(
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
                        "Conducción Segura",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

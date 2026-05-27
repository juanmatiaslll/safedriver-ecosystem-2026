import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _apiService = ApiService();
  Timer? _pollingTimer;
  List<AlertModel> _alerts = [];
  bool _hasHighAlert = false;

  @override
  void initState() {
    super.initState();

    _fetchAlerts();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        _fetchAlerts();
      },
    );
  }

  void _fetchAlerts() async {
    final activeAlerts = await _apiService.getAlerts();

    if (activeAlerts != null) {
      setState(() {
        _alerts = activeAlerts;

        _hasHighAlert = activeAlerts.any(
          (alert) =>
              alert.severity.toUpperCase() == 'HIGH' ||
              alert.severity.toUpperCase() == 'ALTA',
        );
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _hasHighAlert ? const Color(0xFFFFE5E5) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor:
            _hasHighAlert ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "SafeDriver Alerts",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(
              _hasHighAlert
                  ? Icons.warning_amber_rounded
                  : Icons.shield_outlined,
              size: 30,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _hasHighAlert
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB),
            child: Column(
              children: [
                Text(
                  _hasHighAlert
                      ? "RIESGO DETECTADO"
                      : "Sistema Operando Correctamente",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasHighAlert
                      ? "Se detectaron alertas de severidad alta"
                      : "No existen alertas críticas actualmente",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _alerts.isEmpty
                ? const Center(
                    child: Text(
                      "No hay alertas activas",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];

                      final isHigh = alert.severity.toUpperCase() == 'HIGH' ||
                          alert.severity.toUpperCase() == 'ALTA';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isHigh
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFFFB020),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              isHigh
                                  ? Icons.warning_rounded
                                  : Icons.notifications_active,
                              color: isHigh
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFFFB020),
                            ),
                          ),
                          title: Text(
                            alert.alertType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "Driver ID: ${alert.driverId}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              alert.severity,
                              style: TextStyle(
                                color: isHigh
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFFFB020),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

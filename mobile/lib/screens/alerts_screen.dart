import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<int> _deletedAlertIds = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedAlertsAndFetch();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAlerts();
    });
  }

  void _loadDeletedAlertsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final savedIds = prefs.getStringList('deleted_alerts_ids') ?? [];
      _deletedAlertIds = savedIds.map((id) => int.parse(id)).toList();
    });
    _fetchAlerts();
  }

  void _fetchAlerts() async {
    try {
      final activeAlerts = await _apiService.getAlerts();
      if (activeAlerts != null && mounted) {
        final int? miDriverId = await _apiService.getCurrentDriverId();
        final int idFiltrado = miDriverId ?? -1; 

        setState(() {
          _alerts = activeAlerts.where((alert) {
            return alert.driverId == idFiltrado && !_deletedAlertIds.contains(alert.id);
          }).toList();
          
          _hasHighAlert = _alerts.any((alert) =>
              alert.severity.trim().toUpperCase() == 'ALTO' ||
              alert.severity.trim().toUpperCase() == 'HIGH' ||
              alert.severity.trim().toUpperCase() == 'ALTA');
        });
      }
    } catch (e) {
      debugPrint("Error controlado en el Polling: $e");
    }
  }

  // 🎯 PUNTO 4: Lógica para registrar conductor vía modal
  void _showAddDriverDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dniController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrar Conductor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre del Conductor")),
            TextField(controller: dniController, decoration: const InputDecoration(labelText: "DNI")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              bool success = await _apiService.createDriver(nameController.text, dniController.text);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conductor guardado con éxito")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar conductor")));
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _deleteAlertPermanently(int alertId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _deletedAlertIds.add(alertId);
      _alerts.removeWhere((alert) => alert.id == alertId);
    });
    List<String> stringIds = _deletedAlertIds.map((id) => id.toString()).toList();
    await prefs.setStringList('deleted_alerts_ids', stringIds);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); 
    super.dispose();
  }

  Color _getCardColor(String severity) {
    final sev = severity.trim().toUpperCase();
    if (sev == 'ALTO' || sev == 'HIGH' || sev == 'ALTA') return Colors.red.shade400;
    if (sev == 'BAJO' || sev == 'LOW') return Colors.green.shade400;
    return Colors.amber.shade200;
  }

  Color _getTextColor(String severity) {
    final sev = severity.trim().toUpperCase();
    if (sev == 'ALTO' || sev == 'HIGH' || sev == 'ALTA' || sev == 'LOW') return Colors.white;
    return Colors.black;
  }

  String _getHoraReal(AlertModel alert) {
    try {
      final dynamic timestamp = (alert as dynamic).timestamp ?? (alert as dynamic).createdAt;
      if (timestamp != null) {
        String tsStr = timestamp.toString().trim();
        DateTime dateTimeUtc = DateTime.parse(tsStr);
        if (!tsStr.endsWith('Z') && !tsStr.contains('+')) {
          dateTimeUtc = DateTime.utc(dateTimeUtc.year, dateTimeUtc.month, dateTimeUtc.day, dateTimeUtc.hour, dateTimeUtc.minute, dateTimeUtc.second);
        }
        DateTime dateTimeLocal = dateTimeUtc.toLocal();
        return "${dateTimeLocal.hour.toString().padLeft(2, '0')}:${dateTimeLocal.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) { debugPrint("Error formateando hora: $e"); }
    return "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hasHighAlert ? Colors.red.shade100 : Colors.white,
      appBar: AppBar(
        title: const Text("Panel de Alertas (Polling)"),
        actions: [
          if (_hasHighAlert) const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.gpp_bad, color: Colors.red, size: 30)),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              _pollingTimer?.cancel();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt_token');
              await prefs.remove('current_driver_id');
              await prefs.remove('deleted_alerts_ids');
              setState(() { _alerts.clear(); _deletedAlertIds.clear(); _hasHighAlert = false; });
              if (mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      // 🚀 BOTÓN FLOTANTE AGREGADO:
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple.shade200,
        onPressed: () => _showAddDriverDialog(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _alerts.isEmpty
          ? const Center(child: Text("No hay alertas activas en tiempo real."))
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                final cardColor = _getCardColor(alert.severity);
                final textColor = _getTextColor(alert.severity);
                final horaAlerta = _getHoraReal(alert);

                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("Tipo: ${alert.alertType}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Driver ID: ${alert.driverId}", style: TextStyle(color: textColor.withOpacity(0.85))),
                        Text("Hora Real: $horaAlerta", style: TextStyle(color: textColor.withOpacity(0.75), fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Sev: ${alert.severity}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.delete, color: textColor.withOpacity(0.8)),
                          onPressed: () => _deleteAlertPermanently(alert.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
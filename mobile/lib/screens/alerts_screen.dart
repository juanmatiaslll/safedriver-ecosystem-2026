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
    _fetchAlerts(); // Primera ejecución inmediata al cargar la pantalla
    
    // Configurar Polling estricto cada 3 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchAlerts();
    });
  }

  void _fetchAlerts() async {
    final activeAlerts = await _apiService.getAlerts();
    if (activeAlerts != null) {
      setState(() {
        _alerts = activeAlerts;
        
        // Verifica si existe alguna alerta con severidad alta usando el modelo estructurado
        _hasHighAlert = activeAlerts.any((alert) =>
            alert.severity.toUpperCase() == 'HIGH' ||
            alert.severity.toUpperCase() == 'ALTA');
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Evita memory leaks al destruir el widget (Ej. cerrar sesión)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cambia dinámicamente el fondo si se detecta una alerta de riesgo alto
      backgroundColor: _hasHighAlert ? Colors.red.shade100 : Colors.white,
      appBar: AppBar(
        title: const Text("Panel de Alertas (Polling)"),
        actions: [
          if (_hasHighAlert)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.gpp_bad, color: Colors.red, size: 30),
            )
        ],
      ),
      body: _alerts.isEmpty
          ? const Center(child: Text("No hay alertas activas en tiempo real."))
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index]; 
                final isHigh = alert.severity.toUpperCase() == 'HIGH' ||
                               alert.severity.toUpperCase() == 'ALTA';
                return Card(
                  color: isHigh ? Colors.red.shade400 : Colors.amber.shade200,
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      "Tipo: ${alert.alertType}", 
                      style: TextStyle(
                        color: isHigh ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Driver ID: ${alert.driverId}",
                      style: TextStyle(
                        color: isHigh ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    trailing: Text(
                      "Sev: ${alert.severity}",
                      style: TextStyle(
                        color: isHigh ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
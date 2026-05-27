import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _apiService = ApiService();
  final AudioPlayer _player = AudioPlayer();
  Timer? _pollingTimer;
  List<AlertModel> _alerts = [];
  bool _hasHighAlert = false;
  bool _showingEmergency = false;
  Set<int> _knownAlertIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchAlerts(),
    );
  }

  void _fetchAlerts() async {
    final activeAlerts = await _apiService.getAlerts();
    if (activeAlerts == null) return;

    setState(() {
      _alerts = activeAlerts;
      _hasHighAlert = activeAlerts.any(
        (a) => a.severity.toUpperCase() == 'HIGH' || a.severity.toUpperCase() == 'ALTA',
      );

      bool hasNewHighAlert = activeAlerts.any(
        (a) => !_knownAlertIds.contains(a.id) &&
            (a.severity.toUpperCase() == 'HIGH' || a.severity.toUpperCase() == 'ALTA'),
      );

      if (_knownAlertIds.isNotEmpty && hasNewHighAlert && !_showingEmergency) {
        _showEmergencyScreen();
      }

      _knownAlertIds = activeAlerts.map((a) => a.id).toSet();
    });
  }

  void _showEmergencyScreen() {
    _showingEmergency = true;
    _player.setVolume(1.0);
    _player.play(AssetSource('alarm.mp3'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFB91C1C),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 120),
                    const SizedBox(height: 25),
                    const Text('ALERTA DE FATIGA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 34,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('CONDUCTOR EN RIESGO',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 22)),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        _player.stop();
                        _showingEmergency = false;
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Resolver Alerta',
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDriverDialog() {
    final nameCtrl = TextEditingController();
    final dniCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar Conductor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nombre",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dniCtrl,
              decoration: const InputDecoration(
                labelText: "DNI",
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final dni = dniCtrl.text.trim();
              if (name.isEmpty || dni.isEmpty) return;
              bool ok = await _apiService.createDriver(name, dni);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? "Conductor creado" : "Error al crear conductor"),
                  backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  void _showSimulateAlertDialog() {
    final idCtrl = TextEditingController();
    String selectedType = "FATIGA";
    String selectedSeverity = "ALTA";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Simular Alerta"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "ID del Conductor",
                  prefixIcon: Icon(Icons.drive_eta),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Tipo de alerta",
                  prefixIcon: Icon(Icons.warning),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "FATIGA", child: Text("Fatiga")),
                  DropdownMenuItem(value: "DISTRACCION", child: Text("Distracción")),
                  DropdownMenuItem(value: "VELOCIDAD", child: Text("Velocidad")),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedSeverity,
                decoration: const InputDecoration(
                  labelText: "Severidad",
                  prefixIcon: Icon(Icons.arrow_upward),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "BAJA", child: Text("Baja")),
                  DropdownMenuItem(value: "MEDIA", child: Text("Media")),
                  DropdownMenuItem(value: "ALTA", child: Text("Alta")),
                  DropdownMenuItem(value: "CRITICA", child: Text("Crítica")),
                ],
                onChanged: (v) => setDialogState(() => selectedSeverity = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = int.tryParse(idCtrl.text.trim());
                if (id == null) return;
                bool ok = await _apiService.createAlert(id, selectedType, selectedSeverity);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? "Alerta creada" : "Error: conductor no existe"),
                    backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text("Generar Alerta"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _player.dispose();
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
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              _hasHighAlert
                  ? Icons.warning_amber_rounded
                  : Icons.shield_outlined,
              size: 30,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == "driver") _showCreateDriverDialog();
              if (value == "alert") _showSimulateAlertDialog();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "driver",
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text("Agregar Conductor"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: "alert",
                child: ListTile(
                  leading: Icon(Icons.add_alert),
                  title: Text("Simular Alerta"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                      style: TextStyle(fontSize: 18, color: Colors.grey),
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
                              "Conductor: ${alert.driverId}",
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

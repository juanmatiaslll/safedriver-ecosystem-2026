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
  bool _isAdmin = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadAlerts();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAlerts());
  }

  Future<void> _loadRole() async {
    final role = await _apiService.getRoleFromToken();
    if (!mounted) return;
    setState(() {
      _isAdmin = role == "ADMIN";
    });
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

  Future<void> _confirmarYLimpiarAlertas() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limpiar historial de alertas"),
        content: const Text(
          "Esta acción eliminará TODAS las alertas del sistema (activas e inactivas). "
          "No se puede deshacer. ¿Deseas continuar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Sí, eliminar todo"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _clearing = true);
    final ok = await _apiService.deleteAllAlerts();
    setState(() => _clearing = false);

    if (!mounted) return;

    if (ok) {
      await _loadAlerts(); // refresca la lista al instante (quedará vacía)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Historial de alertas eliminado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo limpiar el historial. Intenta de nuevo.")),
      );
    }
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
          padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Alertas activas: $_total",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SafeDriverTheme.textSecondary,
                ),
              ),
              if (_isAdmin)
                _clearing
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        tooltip: "Limpiar historial de alertas",
                        onPressed: _confirmarYLimpiarAlertas,
                      ),
            ],
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
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_model.dart';
import '../widgets/driver_card.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});
  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<DriverModel> _drivers = [];
  Map<int, Map<String, dynamic>> _telemetryMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final drivers = await _apiService.getDrivers();
    if (drivers.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Optimización: Llamadas en paralelo para telemetría
    final telemetryFutures = drivers.map((d) async {
      final t = await _apiService.getLatestTelemetry(d.id);
      return MapEntry(d.id, t);
    });

    final results = await Future.wait(telemetryFutures);
    final Map<int, Map<String, dynamic>> telemetryMap = {};
    
    for (final entry in results) {
      if (entry.value != null) telemetryMap[entry.key] = entry.value!;
    }

    if (!mounted) return;
    setState(() {
      _drivers = drivers;
      _telemetryMap = telemetryMap;
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
      appBar: AppBar(title: const Text("Flota")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, i) {
                final driver = _drivers[i];
                return Stack(
                  children: [
                    DriverCard(
                      driver: driver,
                      telemetry: _telemetryMap[driver.id],
                    ),
                    // Indicador de ruta según MT.5
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Icon(
                        driver.isOnRoute ? Icons.location_on : Icons.location_off,
                        color: driver.isOnRoute ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
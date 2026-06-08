import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_model.dart';
import '../widgets/driver_card.dart';

class FleetScreen extends StatefulWidget {
  // Eliminamos 'const' aquí porque la clase no es constante
  FleetScreen({super.key});
  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<DriverModel> _drivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final drivers = await _apiService.getDrivers();
    
    // Si no hay conductores, simplemente actualizamos el estado de carga
    if (!mounted) return;
    
    setState(() {
      _drivers = drivers;
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
                return DriverCard(
                  driver: _drivers[i],
                  // Ya no pasamos telemetry aquí, 
                  // la tarjeta lo obtiene de driver.lastTelemetry
                );
              },
            ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final ApiService _apiService = ApiService();
  final AudioPlayer _player = AudioPlayer();

  bool _loading = true;
  bool _isOnRoute = false;
  Map<String, dynamic>? _telemetry;
  Timer? _telemetryTimer;

  String _driverName = "";
  String _driverDni = "";

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
    _loadDriverInfo();
    _loadTelemetry();
    _telemetryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadTelemetry(),
    );
  }

  Future<void> _loadDriverInfo() async {
    final driverId = await _apiService.getDriverIdFromToken();
    if (driverId == null) return;
    final drivers = await _apiService.getDrivers();
    try {
      final driver = drivers.firstWhere((d) => d.id == driverId);
      if (!mounted) return;
      setState(() {
        _driverName = driver.name;
        _driverDni = driver.dni;
        _isOnRoute = driver.isOnRoute;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRoute() async {
    final result = await _apiService.toggleRoute();
    if (result != null && mounted) {
      setState(() => _isOnRoute = result);
    }
  }

  Future<void> _loadTelemetry() async {
    final driverId = await _apiService.getDriverIdFromToken();
    if (driverId == null) return;

    final telemetry = await _apiService.getLatestTelemetry(driverId);
    if (!mounted) return;
    setState(() => _telemetry = telemetry);

    final fatigue = (telemetry?['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (telemetry?['speed'] as num?)?.toDouble() ?? 0;
    final isHigh = fatigue > 80 || speed > 120;

    if (isHigh) {
      final asset = fatigue > 80 ? 'peligro_fatiga.mp3' : 'peligro_velocidad.mp3';
      await _player.setVolume(1.0);
      await _player.play(AssetSource(asset));
    } else {
      await _player.stop();
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _statusText(double fatigue, double speed) {
    if (fatigue > 80) return "PELIGRO - FATIGA CRITICA";
    if (speed > 120) return "PELIGRO - VELOCIDAD EXCESIVA";
    if (fatigue > 60) return "PRECAUCION - FATIGA ELEVADA";
    if (speed > 100) return "PRECAUCION - VELOCIDAD ELEVADA";
    return "CONDUCCION SEGURA";
  }

  Color _statusColor(double fatigue, double speed) {
    if (fatigue > 80 || speed > 120) return Colors.red;
    if (fatigue > 60 || speed > 100) return Colors.orange;
    return Colors.green;
  }

  bool _isSafe(double fatigue, double speed) {
    return fatigue <= 60 && speed <= 100;
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
    final color = _statusColor(fatigue, speed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: color.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_statusText(fatigue, speed),
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
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
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
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
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
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
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

  Widget _buildStatusPanel() {
    final fatigue = (_telemetry?['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry?['speed'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(fatigue, speed);
    final isGreen = _isSafe(fatigue, speed);

    return Expanded(
      child: Center(
        child: isGreen
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 120),
                  const SizedBox(height: 20),
                  const Text("Sin alertas activas",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              )
            : Text(_statusText(fatigue, speed),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fatigue = (_telemetry?['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry?['speed'] as num?)?.toDouble() ?? 0;

    Color backgroundColor;
    if (fatigue > 80 || speed > 120) {
      backgroundColor = Colors.red.shade50;
    } else if (fatigue > 60 || speed > 100) {
      backgroundColor = Colors.orange.shade50;
    } else {
      backgroundColor = Colors.green.shade50;
    }

    return Scaffold(
      backgroundColor: _isOnRoute ? backgroundColor : const Color(0xFF0F172A),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Hola, $_driverName - DNI: $_driverDni",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isOnRoute ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                if (!_isOnRoute)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 80, color: Colors.white54),
                          const SizedBox(height: 20),
                          const Text(
                            "Fuera de ruta",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildTelemetryPanel(),
                  _buildStatusPanel(),
                ],
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        onPressed: _toggleRoute,
                        icon: Icon(_isOnRoute ? Icons.stop_circle : Icons.play_circle_fill, size: 32),
                        label: Text(
                          _isOnRoute ? "TERMINAR RUTA" : "INICIAR RUTA",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnRoute ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

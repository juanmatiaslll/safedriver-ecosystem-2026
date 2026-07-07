import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../theme.dart';
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
  bool _audioMuted = false;
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

    if (isHigh && !_audioMuted) {
      final asset =
          fatigue > 80 ? 'peligro_fatiga.mp3' : 'peligro_velocidad.mp3';

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
    if (fatigue > 80 || speed > 120) return SafeDriverTheme.alta;
    if (fatigue > 60 || speed > 100) return SafeDriverTheme.media;
    return SafeDriverTheme.ok;
  }

  Widget _buildDriverHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SafeDriverTheme.primaryDark,
            Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child: Text(
                  _driverName.isNotEmpty ? _driverName[0].toUpperCase() : "?",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola, $_driverName",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "DNI: $_driverDni",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: _audioMuted
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _audioMuted = !_audioMuted;
                          });
                          if (_audioMuted) {
                            _player.stop();
                          }
                        },
                        child: Icon(
                          _audioMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: SafeDriverTheme.alta,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 2,
                      shadowColor: SafeDriverTheme.alta.withValues(alpha: 0.4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _logout,
                        child: const Icon(Icons.logout, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard() {
    if (_telemetry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 48, color: SafeDriverTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text("Esperando datos del sensor...",
                style: TextStyle(fontSize: 15, color: SafeDriverTheme.textSecondary)),
          ],
        ),
      );
    }

    final fatigue = (_telemetry!['fatigue_level'] as num?)?.toDouble() ?? 0;
    final heart = (_telemetry!['heart_rate'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry!['speed'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(fatigue, speed);
    final statusText = _statusText(fatigue, speed);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: SafeDriverTheme.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    _buildStatusPill(statusText, color),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 20, color: SafeDriverTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text("FATIGA",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SafeDriverTheme.textSecondary,
                                letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${fatigue.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: color,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fatigue / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: color,
                        minHeight: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: SafeDriverTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.favorite, size: 26, color: SafeDriverTheme.alta),
                                const SizedBox(height: 6),
                                Text(
                                  "${heart.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: SafeDriverTheme.textPrimary,
                                  ),
                                ),
                                Text("BPM",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: SafeDriverTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: SafeDriverTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.speed, size: 26,
                                    color: speed > 120
                                        ? SafeDriverTheme.alta
                                        : speed > 100
                                            ? SafeDriverTheme.media
                                            : SafeDriverTheme.primary),
                                const SizedBox(height: 6),
                                Text(
                                  "${speed.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: speed > 120
                                        ? SafeDriverTheme.alta
                                        : speed > 100
                                            ? SafeDriverTheme.media
                                            : SafeDriverTheme.textPrimary,
                                  ),
                                ),
                                Text("km/h",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: SafeDriverTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffRoute() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 100,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 20),
          const Text(
            "Fuera de ruta",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Presiona INICIAR RUTA para comenzar",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fatigue = (_telemetry?['fatigue_level'] as num?)?.toDouble() ?? 0;
    final speed = (_telemetry?['speed'] as num?)?.toDouble() ?? 0;

    Color bgColor;
    if (_isOnRoute) {
      if (fatigue > 80 || speed > 120) {
        bgColor = SafeDriverTheme.alta.withValues(alpha: 0.06);
      } else if (fatigue > 60 || speed > 100) {
        bgColor = SafeDriverTheme.media.withValues(alpha: 0.06);
      } else {
        bgColor = SafeDriverTheme.surface;
      }
    } else {
      bgColor = SafeDriverTheme.primaryDark;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
                children: [
                  _buildDriverHeader(),
                  Expanded(
                    child: _isOnRoute ? _buildTelemetryCard() : _buildOffRoute(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _toggleRoute,
                        icon: Icon(
                          _isOnRoute ? Icons.stop_circle : Icons.play_circle_fill,
                          size: 28,
                        ),
                        label: Text(
                          _isOnRoute ? "TERMINAR RUTA" : "INICIAR RUTA",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnRoute ? SafeDriverTheme.alta : SafeDriverTheme.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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

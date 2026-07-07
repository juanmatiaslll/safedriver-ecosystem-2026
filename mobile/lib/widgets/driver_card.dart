import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../theme.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  final Map<String, dynamic>? telemetry;
  const DriverCard({super.key, required this.driver, this.telemetry});

  Color _fatigueColor(double level) {
    if (level > 80) return SafeDriverTheme.alta;
    if (level > 60) return SafeDriverTheme.media;
    return SafeDriverTheme.ok;
  }

  Color _speedColor(double speed) {
    if (speed > 120) return SafeDriverTheme.alta;
    if (speed > 100) return SafeDriverTheme.media;
    return SafeDriverTheme.ok;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOk = driver.status == 'OK';
    final fatigue = telemetry?['fatigue_level'];
    final heart = telemetry?['heart_rate'];
    final speed = telemetry?['speed'];

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isOk ? SafeDriverTheme.ok : SafeDriverTheme.alta).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: isOk ? SafeDriverTheme.ok : SafeDriverTheme.alta, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SafeDriverTheme.textPrimary,
                              )),
                          Text('DNI: ${driver.dni}',
                              style: theme.textTheme.bodySmall?.copyWith(color: SafeDriverTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (telemetry != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      _telemetryChip(theme, "Fatiga", "${fatigue?.toStringAsFixed(0) ?? "--"}%",
                          _fatigueColor(fatigue?.toDouble() ?? 0)),
                      const SizedBox(width: 6),
                      _telemetryChip(theme, "Ritmo", "${heart?.toStringAsFixed(0) ?? "--"} bpm",
                          SafeDriverTheme.primary),
                      const SizedBox(width: 6),
                      _telemetryChip(theme, "Vel", "${speed?.toStringAsFixed(0) ?? "--"} km/h",
                          _speedColor(speed?.toDouble() ?? 0)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 20,
          child: Icon(
            driver.isOnRoute ? Icons.location_on : Icons.location_off,
            color: driver.isOnRoute ? SafeDriverTheme.accent : SafeDriverTheme.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _telemetryChip(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

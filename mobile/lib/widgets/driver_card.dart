import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  final Map<String, dynamic>? telemetry;
  const DriverCard({super.key, required this.driver, this.telemetry});

  Color _fatigueColor(double level) {
    if (level > 80) return Colors.red;
    if (level > 60) return Colors.orange;
    return Colors.green;
  }

  Color _speedColor(double speed) {
    if (speed > 120) return Colors.red;
    if (speed > 100) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isOk = driver.status == 'OK';
    final fatigue = telemetry?['fatigue_level'];
    final heart = telemetry?['heart_rate'];
    final speed = telemetry?['speed'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: isOk ? Colors.green : Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('DNI: ${driver.dni} - ${driver.status}'),
                    ],
                  ),
                ),
              ],
            ),
            if (telemetry != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  _telemetryChip("Fatiga", "${fatigue?.toStringAsFixed(0) ?? "--"}%", _fatigueColor(fatigue?.toDouble() ?? 0)),
                  const SizedBox(width: 8),
                  _telemetryChip("Ritmo", "${heart?.toStringAsFixed(0) ?? "--"} bpm", Colors.blue),
                  const SizedBox(width: 8),
                  _telemetryChip("Vel", "${speed?.toStringAsFixed(0) ?? "--"} km/h", _speedColor(speed?.toDouble() ?? 0)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _telemetryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
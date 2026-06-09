import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onResolve;

  const AlertCard({super.key, required this.alert, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    // MT.3: Formateo de hora (Asumiendo que alert.createdAt es DateTime)
    final DateTime time = alert.createdAt ?? DateTime.now();
    final String formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // Mantenemos tu borde lateral de severidad
      shape: Border(
        left: BorderSide(
          color: alert.severity == 'ALTA' ? Colors.red : Colors.orange, 
          width: 5
        )
      ),
      child: ListTile(
        // MT.2: Usamos alert.driverName que ya viene en el modelo
        title: Text(
          alert.driverName, 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${alert.alertType} • Severidad: ${alert.severity}'),
            Text(
              'Hora: $formattedTime', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: onResolve,
        ),
      ),
    );
  }
}
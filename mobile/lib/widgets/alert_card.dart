import 'package:flutter/material.dart';
import '../models/alert_model.dart'; // Asegúrate de crear este modelo también

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onResolve;

  const AlertCard({super.key, required this.alert, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: Border(left: BorderSide(color: alert.severity == 'ALTA' ? Colors.red : Colors.orange, width: 5)),
      child: ListTile(
        title: Text('${alert.driverName} - ${alert.alertType}'),
        subtitle: Text('Severidad: ${alert.severity}'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: onResolve, // Aquí llamaremos a la lógica de resolver
        ),
      ),
    );
  }
}
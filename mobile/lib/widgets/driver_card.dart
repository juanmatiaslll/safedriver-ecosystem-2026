import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  const DriverCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final isOk = driver.status == 'OK';
    return Card(
      child: ListTile(
        leading: Icon(Icons.person, color: isOk ? Colors.green : Colors.red),
        title: Text(driver.name),
        subtitle: Text('DNI: ${driver.dni} - Status: ${driver.status}'),
      ),
    );
  }
}
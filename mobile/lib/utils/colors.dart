import 'package:flutter/material.dart';

Color severityToColor(String severity) {
  switch (severity.toUpperCase()) {
    case 'BAJA':
      return Colors.blue;

    case 'MEDIA':
      return Colors.orange;

    case 'ALTA': 
      return Colors.red;
    case 'CRITICA':
    case 'HIGH':
      return Colors.red;

    default:
      return Colors.grey;
  }
}
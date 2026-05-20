import 'dart:convert';

class AlertModel {
  final int id;
  final int driverId;   // 👈 Asegúrate de que termine en 'Id' con la I mayúscula
  final String alertType;
  final String severity; // 👈 Asegúrate de que esté todo en minúsculas
  final bool isActive;

  AlertModel({
    required this.id,
    required this.driverId,
    required this.alertType,
    required this.severity,
    required this.isActive,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  // 💡 Revisa que este método se llame EXACTAMENTE 'fromJsonList'
  static List<AlertModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AlertModel.fromJson(json)).toList();
  }
}
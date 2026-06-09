class AlertModel {
  final int id;
  final int driverId;
  final String alertType;
  final String severity;
  final bool isActive;
  final DateTime? createdAt; // Cambiamos de String? a DateTime?
  final String driverName;   // Lo hacemos no nulo para evitar errores de UI

  AlertModel({
    required this.id,
    required this.driverId,
    required this.alertType,
    required this.severity,
    required this.isActive,
    this.createdAt,
    required this.driverName,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      isActive: json['is_active'] as bool,
      // Convertimos el String (ISO 8601) a objeto DateTime
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      driverName: json['driver_name'] as String? ?? 'Desconocido',
    );
  }

  static List<AlertModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AlertModel.fromJson(json)).toList();
  }
}
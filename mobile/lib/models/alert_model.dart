class AlertModel {
  final int id;
  final int driverId;
  final String alertType;
  final String severity;
  final bool isActive;
  final String? createdAt;
  final String? driverName;

  AlertModel({
    required this.id,
    required this.driverId,
    required this.alertType,
    required this.severity,
    required this.isActive,
    this.createdAt,
    this.driverName,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String?,
      driverName: json['driver_name'] as String?,
    );
  }

  static List<AlertModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AlertModel.fromJson(json)).toList();
  }
}
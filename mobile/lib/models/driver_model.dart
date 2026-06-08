class DriverModel {
  final int id;
  final String name;
  final String dni;
  final String status;
  final Map<String, dynamic>? lastTelemetry;

  DriverModel({required this.id, required this.name, required this.dni, required this.status, this.lastTelemetry});

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      name: json['name'],
      dni: json['dni'],
      status: json['status'],
      lastTelemetry: json['last_telemetry'] != null
          ? Map<String, dynamic>.from(json['last_telemetry'])
          : null,
    );
  }
}
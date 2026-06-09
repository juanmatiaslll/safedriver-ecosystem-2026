class DriverModel {
  final int id;
  final String name;
  final String dni;
  final String status;
  final bool isOnRoute;

  DriverModel({required this.id, required this.name, required this.dni, required this.status, required this.isOnRoute});

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'],
      name: json['name'],
      dni: json['dni'],
      status: json['status'],
      isOnRoute: json['is_on_route'] ?? false,
    );
  }
}
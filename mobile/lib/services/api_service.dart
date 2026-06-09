import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safedriver_mobile/main.dart';

import '../models/driver_model.dart';
import '../models/alert_model.dart';
import '../screens/login_screen.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000";
    } else {
      return "http://10.0.2.2:8000";
    }
  }

  Future<bool> registerDriver(
    String name,
    String dni,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register-driver');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "dni": dni,
          "password": password,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error en registerDriver: $e");
      return false;
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Map<String, dynamic>? _decodeToken(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(
        base64Url.decode(normalized),
      );

      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRoleFromToken() async {
    final token = await getToken();

    if (token == null) return null;

    final decoded = _decodeToken(token);

    return decoded?['rol'];
  }

  Future<int?> getDriverIdFromToken() async {
    final token = await getToken();

    if (token == null) return null;

    final decoded = _decodeToken(token);

    return decoded?['driver_id'];
  }

  Future<bool> isTokenExpired() async {
    final token = await getToken();

    if (token == null) return true;

    final decoded = _decodeToken(token);

    if (decoded == null) return true;

    final exp = decoded['exp'];

    if (exp == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return now >= exp;
  }

  Future<void> handleUnauthorized() async {
    await clearToken();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<bool> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('jwt_token', token);

        return true;
      }

      return false;
    } catch (e) {
      print("Error en login: $e");
      return false;
    }
  }

  Future<bool> register(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error en register: $e");
      return false;
    }
  }

  Future<List<AlertModel>?> getAlerts({bool todayOnly = false}) async {
    final url = Uri.parse('$baseUrl/alerts${todayOnly ? "?date=today" : ""}');

    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return null;
      }

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = jsonDecode(response.body);

        return AlertModel.fromJsonList(decodedList);
      }

      return null;
    } catch (e) {
      print("Error al obtener alertas: $e");
      return null;
    }
  }

  Future<bool> createDriver(
    String name,
    String dni,
  ) async {
    final url = Uri.parse('$baseUrl/drivers');

    final token = await getToken();

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": name,
          "dni": dni,
        }),
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return false;
      }

      return response.statusCode == 201;
    } catch (e) {
      print("Error al crear conductor: $e");
      return false;
    }
  }

  Future<bool> createAlert(
    int driverId,
    String alertType,
    String severity,
  ) async {
    final url = Uri.parse('$baseUrl/alerts');

    final token = await getToken();

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "driver_id": driverId,
          "alert_type": alertType,
          "severity": severity,
        }),
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return false;
      }

      return response.statusCode == 201;
    } catch (e) {
      print("Error al crear alerta: $e");
      return false;
    }
  }

  Future<bool> resolveAlert(int alertId) async {
    final url = Uri.parse('$baseUrl/alerts/$alertId/resolve');
    final token = await getToken();

    if (token == null) return false;

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      print("Error al resolver alerta: $e");
      return false;
    }
  }

  Future<List<DriverModel>> getDrivers() async {
    final url = Uri.parse('$baseUrl/drivers');
    final token = await getToken();

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return [];
      }

      if (response.statusCode == 200) {
        // Aquí convertimos los datos de 'dynamic' a una lista de 'DriverModel'
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => DriverModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error al obtener conductores: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestTelemetry(int driverId) async {
    final url = Uri.parse('$baseUrl/telemetry/latest/$driverId');

    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return null;
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print("Error en getLatestTelemetry: $e");
      return null;
    }
  }

  Future<bool?> toggleRoute() async {
    final url = Uri.parse('$baseUrl/drivers/me/route');

    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        await handleUnauthorized();
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data["is_on_route"];
      }

      return null;
    } catch (e) {
      print("Error toggleRoute: $e");
      return null;
    }
  }
}

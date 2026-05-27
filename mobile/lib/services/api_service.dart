import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import '../models/alert_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; 
    } else {
      return "http://10.0.2.2:8000";  
    }
  }

  // ── 1. Login Dinámico ──────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login'); 
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['access_token']);
        
        // Lógica de ID de conductor
        String userLower = username.trim().toLowerCase();
        int driverId = (userLower.contains('mateo')) ? 1 : 
                       (userLower.contains('sebas') || userLower.contains('sebastian')) ? 2 : 
                       (userLower.hashCode.abs() % 1000 + 3);
        
        await prefs.setInt('current_driver_id', driverId);
        return true;
      }
      return false;
    } catch (e) {
      print("Error en login: $e");
      return false;
    }
  }
  
  // ── 2. Registro (Sin token) ──────────────────────────────────────────
  Future<bool> register(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/register'); 
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error en registro: $e");
      return false;
    }
  }

  // ── 3. Crear Conductor (Con Token JWT) ────────────────────────────────
  Future<bool> createDriver(String name, String dni) async {
    final url = Uri.parse('$baseUrl/drivers');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      print("Error: No se encontró token, el usuario debe estar logueado.");
      return false;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name, "dni": dni}),
      );
      
      // Retorna true si el servidor responde 201 (Creado) o 200 (OK)
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error al crear conductor: $e");
      return false;
    }
  }
  
  // ── 4. Obtener Alertas Activas ──────────────────────────────────────────
  Future<List<AlertModel>?> getAlerts() async { 
    final url = Uri.parse('$baseUrl/alerts');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", 
        },
      );

      if (response.statusCode == 200) {
        return AlertModel.fromJsonList(jsonDecode(response.body)); 
      }
      return null; 
    } catch (e) {
      print("Error al obtener alertas: $e");
      return null; 
    }
  } 

  Future<int?> getCurrentDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_driver_id');
  }
}
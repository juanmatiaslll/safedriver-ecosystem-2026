import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; 
import '../models/alert_model.dart';

class ApiService {
  // ── Configuración automática de IP según la plataforma ──
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000"; // URL si estás probando en el navegador web
    } else {
      return "http://10.0.2.2:8000";  // IP mágica si estás usando el emulador de Android
    }
  }

  // ── 1. Login y Guardar JWT ─────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login'); // 👈 Ahora usa el get dinámico
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data['access_token'];
        
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
  
// ── 2. Obtener Alertas Activas (Tipado Fuerte) ────────────────────
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
        final List<dynamic> decodedList = jsonDecode(response.body);
        return AlertModel.fromJsonList(decodedList); 
      }
      return null; // Si el status no es 200, retorna null
    } catch (e) {
      print("Error al obtener alertas: $e");
      return null; // Si se cae por red, retorna null
    }
  } 
}
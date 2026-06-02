import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'fleet_screen.dart';
import 'alerts_feed_screen.dart';
import 'login_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  final List<Widget> _pages = [FleetScreen(), AlertsFeedScreen()];

  void _logout() async {
    await _apiService.clearToken();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: _logout,
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Flota'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alertas'),
        ],
      ),
    );
  }
}
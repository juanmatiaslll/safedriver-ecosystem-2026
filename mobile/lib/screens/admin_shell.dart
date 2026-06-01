import 'package:flutter/material.dart';
import 'fleet_screen.dart';
import 'alerts_feed_screen.dart'; // Crea este archivo después

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  final List<Widget> _pages = [FleetScreen(), AlertsFeedScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
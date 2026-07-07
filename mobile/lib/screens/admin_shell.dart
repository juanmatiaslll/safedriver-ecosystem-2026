import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'fleet_screen.dart';
import 'alerts_feed_screen.dart';
import 'login_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        toolbarHeight: 56,
        title: null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: SafeDriverTheme.accent,
              indicatorWeight: 3,
              labelColor: SafeDriverTheme.accent,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard, size: 20), text: "Dashboard"),
                Tab(icon: Icon(Icons.directions_car, size: 20), text: "Flota"),
                Tab(icon: Icon(Icons.notifications, size: 20), text: "Alertas"),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: const [
              DashboardScreen(),
              FleetScreen(),
              AlertsFeedScreen(),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 16,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Material(
                color: SafeDriverTheme.alta,
                borderRadius: BorderRadius.circular(21),
                elevation: 4,
                shadowColor: SafeDriverTheme.alta.withValues(alpha: 0.4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: _logout,
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

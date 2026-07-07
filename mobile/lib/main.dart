import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_shell.dart';
import 'screens/driver_home.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SafeDriverApp());
}

class SafeDriverApp extends StatelessWidget {
  const SafeDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SafeDriver Mobile',
      debugShowCheckedModeBanner: false,
      theme: SafeDriverTheme.theme,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final ApiService _apiService = ApiService();
  bool _checking = true;
  Widget _destination = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        _checking = false;
        _destination = const LoginScreen();
      });
      return;
    }

    final expired = await _apiService.isTokenExpired();

    if (expired) {
      await _apiService.clearToken();
      setState(() {
        _checking = false;
        _destination = const LoginScreen();
      });
      return;
    }

    final role = await _apiService.getRoleFromToken();

    setState(() {
      _checking = false;
      if (role == "ADMIN") {
        _destination = const AdminShell();
      } else if (role == "CONDUCTOR") {
        _destination = const DriverHome();
      } else {
        _destination = const LoginScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _destination;
  }
}
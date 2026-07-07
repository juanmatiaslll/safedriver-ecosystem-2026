import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'register_screen.dart';
import 'admin_shell.dart';
import 'driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _apiService = ApiService();

  late TabController _tabController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _apiService.login(
      username,
      password,
    );

    setState(() => _isLoading = false);

    if (success) {
      final token = await _apiService.getToken();
      print("TOKEN = $token");

      final role = await _apiService.getRoleFromToken();
      print("ROL JWT = $role");

      if (!mounted) return;

      bool esConductor = _tabController.index == 0;

      if (esConductor && role != "CONDUCTOR") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Esta cuenta no es de conductor",
            ),
          ),
        );
        return;
      }

      if (!esConductor && role != "ADMIN") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Esta cuenta no es de administrador",
            ),
          ),
        );
        return;
      }

      if (role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminShell(),
          ),
        );
      }

      if (role == "CONDUCTOR") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverHome(),
          ),
        );
      }
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Credenciales incorrectas",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriverTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: SafeDriverTheme.primaryDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 130,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Bienvenido",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: SafeDriverTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sistema Inteligente de Alertas",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 25),
                TabBar(
                  controller: _tabController,
                  onTap: (_) {
                    setState(() {});
                  },
                  labelColor: SafeDriverTheme.accent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: SafeDriverTheme.accent,
                  tabs: const [
                    Tab(text: "Soy Conductor"),
                    Tab(text: "Soy Administrador"),
                  ],
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _usernameController,
                  keyboardType:
                      isDriverTab ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: isDriverTab ? "DNI" : "Usuario",
                    prefixIcon: Icon(
                      isDriverTab ? Icons.badge : Icons.person,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeDriverTheme.accent,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                if (isDriverTab) ...[
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "¿No tienes cuenta? Regístrate",
                      style: TextStyle(
                        color: SafeDriverTheme.accent,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

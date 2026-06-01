import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  void _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError("Completa todos los campos");
      return;
    }

    if (password != confirm) {
      _showError("Las contraseñas no coinciden");
      return;
    }

    if (password.length < 4) {
      _showError("La contraseña debe tener al menos 4 caracteres");
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _apiService.register(username, password);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro exitoso. Ahora inicia sesión."),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context);
    } else {
      _showError("El usuario ya existe o hubo un error");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                  height: 100,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Crear Cuenta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Regístrate como operador",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: "Usuario",
                    prefixIcon: const Icon(Icons.person),
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
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Confirmar contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
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
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Registrarse",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "¿Ya tienes cuenta? Inicia sesión",
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

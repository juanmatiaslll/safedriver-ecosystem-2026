import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(255, 240, 65, 65), const Color.fromARGB(255, 78, 169, 243)],
          ),
        ),
        child: Column(
          children: [
            // Botón de atrás personalizado
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.person_add, size: 100, color: Colors.white),
                    const SizedBox(height: 20),
                    const Text("Registrar Usuario", style: TextStyle(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Usuario",
                        hintStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Contraseña",
                        hintStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 50),
                    _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          ),
                          onPressed: () async {
                            setState(() => _isLoading = true);
                            bool success = await _apiService.register(_usernameController.text, _passwordController.text);
                            setState(() => _isLoading = false);
                            
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Éxito!")));
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error")));
                            }
                          },
                          child: const Text("REGISTRAR", style: TextStyle(color: Colors.purple)),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
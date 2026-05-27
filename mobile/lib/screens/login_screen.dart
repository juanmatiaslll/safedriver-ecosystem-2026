import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // 🎨 Fondo Degradado idéntico a tu referencia (Rosa Pastel a Azul Turquesa)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 241, 73, 81), 
              Color.fromARGB(255, 152, 172, 236), 
            ],
          ),
        ),
        child: Column(
          children: [
            // 🏷️ Franja superior translúcida integrada
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 30, bottom: 10, left: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
                ),
              ),
              child: const Text(
                "SafeDriver Login",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            // 📜 Contenedor de Formulario Scrolleable
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 💡 TU LOGO DE ESCUDO: Centrado y bien dimensionado
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/logo_safedriver.png', //  carpeta assets
                          height: 180,
                          width: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // 👤 Icono minimalista de la personita arriba del texto (Estilo tu imagen)
                      const Icon(
                        Icons.person_pin_outlined,
                        size: 45,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 5),
                      
                      const Text(
                        "User Login", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // 👤 Input de Usuario Estilizado (Línea Inferior)
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Color(0xFF2E4D68), fontSize: 16, fontWeight: FontWeight.w500),
                        cursorColor: const Color(0xFF2E4D68),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF2E4D68), size: 24),
                          hintText: "Usuario",
                          hintStyle: TextStyle(color: Color(0x992E4D68)),
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x662E4D68), width: 1.5),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2E4D68), width: 2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // 🔒 Input de Contraseña Estilizado (Línea Inferior)
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xFF2E4D68), fontSize: 16, fontWeight: FontWeight.w500),
                        cursorColor: const Color(0xFF2E4D68),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF2E4D68), size: 24),
                          hintText: "Contraseña",
                          hintStyle: TextStyle(color: Color(0x992E4D68)),
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x662E4D68), width: 1.5),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF2E4D68), width: 2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 45),
                      
                      // 🔘 Botón de LOGIN Sólido (Color Corporativo de la Imagen)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4D68), // Azul oscuro idéntico a tu botón de referencia
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4), // Bordes rectos sutiles
                          ),
                        ),
                        onPressed: () async {
                          if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Por favor, rellena todos los campos.")),
                            );
                            return;
                          }
                          
                          bool success = await _apiService.login(
                            _usernameController.text.trim(), 
                            _passwordController.text.trim()
                          );
                          
                          if (success) {
                            Navigator.pushReplacementNamed(context, '/alerts');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Error de credenciales.")),
                            );
                          }
                        },
                        child: const Text(
                          "LOGIN", 
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // 📝 Enlace para ir al Registro (AGREGAR USUARIO)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E4D68)),
                        child: const Text(
                          "¿Eres nuevo? Registrar Usuario", 
                          style: TextStyle(
                            fontSize: 14, 
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
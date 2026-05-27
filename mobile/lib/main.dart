import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'screens/RegisterScreen.dart';
import 'screens/alerts_screen.dart';
import 'screens/login_screen.dart';

// En tu archivo main.dart
void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => LoginScreen(),
      '/register': (context) => RegisterScreen(),
      '/alerts': (context) => AlertsScreen(),
    },
  ));
}

class SafeDriverApp extends StatelessWidget {
  const SafeDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeDriver Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// Pantalla de Emergencia diseñada por Jordy con alarma sonora
class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    playAlarm();
  }

  Future<void> playAlarm() async {
    await player.setVolume(1.0);
    await player.play(AssetSource('alarm.mp3'));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 120),
            SizedBox(height: 30),
            Text(
              'ALERTA DE FATIGA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'CONDUCTOR EN RIESGO',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';

class AlertsFeedScreen extends StatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  State<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends State<AlertsFeedScreen> {
  final ApiService _apiService = ApiService(); // <--- AGREGA ESTO

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alertas")),
      body: FutureBuilder<List<AlertModel>?>(
        future: _apiService.getAlerts(todayOnly: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) => AlertCard(
              alert: snapshot.data![i],
              onResolve: () async {
                // <--- USA LA VARIABLE AQUÍ TAMBIÉN
                await _apiService.resolveAlert(snapshot.data![i].id);
                setState(() {}); 
              },
            ),
          );
        },
      ),
    );
  }
}
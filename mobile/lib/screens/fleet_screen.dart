import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_model.dart';
import '../widgets/driver_card.dart';

class FleetScreen extends StatelessWidget {
  final ApiService _apiService = ApiService(); // <--- AGREGA ESTO


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flota")),
      body: FutureBuilder<List<DriverModel>>( 
        future: _apiService.getDrivers(), 
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, i) => DriverCard(driver: snapshot.data![i]),
          );
        },
      ),
    );
  }
}
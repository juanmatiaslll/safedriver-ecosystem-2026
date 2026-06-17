import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_model.dart';
import '../widgets/driver_card.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});
  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;
  List<DriverModel> _allDrivers = [];
  List<DriverModel> _filteredDrivers = [];
  Map<int, Map<String, dynamic>> _telemetryMap = {};
  bool _loading = true;
  String _filterOption = "todos";

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  Future<void> _loadData() async {
    final drivers = await _apiService.getDrivers();
    if (drivers.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final telemetryFutures = drivers.map((d) async {
      final t = await _apiService.getLatestTelemetry(d.id);
      return MapEntry(d.id, t);
    });

    final results = await Future.wait(telemetryFutures);
    final Map<int, Map<String, dynamic>> telemetryMap = {};

    for (final entry in results) {
      if (entry.value != null) telemetryMap[entry.key] = entry.value!;
    }

    if (!mounted) return;
    setState(() {
      _allDrivers = drivers;
      _telemetryMap = telemetryMap;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    if (_filterOption == "ruta") {
      _filteredDrivers = _allDrivers.where((d) => d.isOnRoute).toList();
    } else {
      _filteredDrivers = List.from(_allDrivers);
    }
  }

  void _setFilter(String option) {
    setState(() {
      _filterOption = option;
      _applyFilter();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flota"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _setFilter,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "todos",
                child: ListTile(
                  leading: Icon(Icons.group),
                  title: Text("Todos"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: "ruta",
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text("Solo en ruta"),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredDrivers.length,
                    itemBuilder: (context, i) {
                      final driver = _filteredDrivers[i];
                      return DriverCard(
                        driver: driver,
                        telemetry: _telemetryMap[driver.id],
                      );
                    },
                  );
                }
                return ListView.builder(
                  itemCount: _filteredDrivers.length,
                  itemBuilder: (context, i) {
                    final driver = _filteredDrivers[i];
                    return DriverCard(
                      driver: driver,
                      telemetry: _telemetryMap[driver.id],
                    );
                  },
                );
              },
            ),
    );
  }
}

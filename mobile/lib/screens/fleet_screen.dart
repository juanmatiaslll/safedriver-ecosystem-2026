import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver_model.dart';
import '../theme.dart';
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Text("Mostrar: ",
                  style: TextStyle(fontSize: 13, color: SafeDriverTheme.textSecondary)),
              const SizedBox(width: 8),
              _buildFilterChip("Todos", "todos"),
              const SizedBox(width: 8),
              _buildFilterChip("Solo en ruta", "ruta"),
            ],
          ),
        ),
        const Divider(height: 1, color: SafeDriverTheme.border),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filterOption == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? SafeDriverTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? SafeDriverTheme.accent : SafeDriverTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : SafeDriverTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:equip_sight/services/dormitory_stats_service.dart';
import 'package:flutter/material.dart';

class DormitoryDashboard extends StatefulWidget {
  final String dormId;

  const DormitoryDashboard({super.key, required this.dormId});

  @override
  State<DormitoryDashboard> createState() => _DormitoryDashboardState();
}

class _DormitoryDashboardState extends State<DormitoryDashboard> {
  final DormitoryStatsService _statsService = DormitoryStatsService();

  final Map<String, Color> statColors = {
    'Машины': Colors.orange,
    'Активные': Colors.green,
    'Неисправные': Colors.red,
  };

  final Map<String, IconData> statIcons = {
    'Машины': Icons.local_laundry_service,
    'Активные': Icons.check_circle,
    'Неисправные': Icons.error,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Панель общежития'), centerTitle: true),
      body: FutureBuilder<Map<String, int>>(
        future: _statsService.getDormitoryStats(widget.dormId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Ошибка загрузки данных',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data!;

          final stats = {
            'Машины': data['machines']!,
            'Активные': data['active']!,
            'Неисправные': data['inactive']!,
          };

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: stats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final key = stats.keys.elementAt(index);
                return _statCard(
                  key,
                  stats[key]!,
                  statColors[key]!,
                  statIcons[key]!,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value, Color color, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  value.toString(),
                  key: ValueKey<int>(value),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

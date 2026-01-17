import 'package:flutter/material.dart';
import 'package:laundry_lens/services/university_stats_service.dart';

class UniversityDashboard extends StatefulWidget {
  final String universityId;

  const UniversityDashboard({super.key, required this.universityId});

  @override
  State<UniversityDashboard> createState() => _UniversityDashboardState();
}

class _UniversityDashboardState extends State<UniversityDashboard> {
  final UniversityStatsService _statsService = UniversityStatsService();

  final Map<String, Color> statColors = {
    'Общежития': Colors.green,
    'Машины': Colors.orange,
    'Активные': Colors.blue,
    'Неисправные': Colors.red,
  };

  final Map<String, IconData> statIcons = {
    'Общежития': Icons.home,
    'Машины': Icons.local_laundry_service,
    'Активные': Icons.check_circle,
    'Неисправные': Icons.error,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель университета'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsService.getUniversityStats(widget.universityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Ошибка загрузки данных',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          final data = snapshot.data!;

          final stats = {
            'Общежития': data['dorms'] ?? 0,
            'Машины': data['machines'] ?? 0,
            'Активные': data['activeMachines'] ?? 0,
            'Неисправные': data['inactiveMachines'] ?? 0,
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
                final title = stats.keys.elementAt(index);
                final value = stats[title]!;
                return _statCard(title, value);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int value) {
    final color = statColors[title]!;
    final icon = statIcons[title]!;

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
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  value.toString(),
                  key: ValueKey<int>(value),
                  style: const TextStyle(
                    fontSize: 32,
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

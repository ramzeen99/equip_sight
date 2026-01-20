import 'package:equip_sight/components/title_app_design.dart';
import 'package:equip_sight/constants.dart';
import 'package:flutter/material.dart';

import '../components/machine_card.dart';
import '../model/model.dart';
import '../pages/onboarding.dart';

class HomeLockedPage extends StatelessWidget {
  static const String id = "HomeLocked";

  const HomeLockedPage({super.key});

  void _showAuthRequired(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Доступ запрещён",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Пожалуйста, зарегистрируйтесь или войдите в систему, чтобы запустить стиральную машину.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _goToOnboarding(context);
                  },
                  icon: const Icon(Icons.app_registration),
                  label: const Text("Зарегистрироваться"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _goToOnboarding(context);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text("Войти в систему"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToOnboarding(BuildContext context) {
    Navigator.pushReplacementNamed(context, OnboardingPage.id);
  }

  @override
  Widget build(BuildContext context) {
    final fakeMachines = [
      Machine(
        id: "1",
        nom: "Стиральная машина A",
        statut: MachineStatus.libre,
        emplacement: "1 этаж",
      ),
      Machine(
        id: "2",
        nom: "Стиральная машина B",
        statut: MachineStatus.libre,
        emplacement: "1 этаж",
      ),
      Machine(
        id: "3",
        nom: "Стиральная машина C",
        statut: MachineStatus.occupe,
        emplacement: "2 этаж",
      ),
      Machine(
        id: "4",
        nom: "Стиральная машина D",
        statut: MachineStatus.termine,
        emplacement: "2 этаж",
      ),
      Machine(
        id: "5",
        nom: "Стиральная машина E",
        statut: MachineStatus.libre,
        emplacement: "3 этаж",
      ),
      Machine(
        id: "6",
        nom: "Стиральная машина F",
        statut: MachineStatus.occupe,
        emplacement: "3 этаж",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF459380),
      appBar: AppBar(
        title: const TitleAppDesign(textTitle: 'EquipSight'),
        backgroundColor: const Color(0xFF459380),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF459380)),
              child: Center(child: Text('EquipSight', style: titreStyle)),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("Войти в систему"),
              onTap: () {
                Navigator.pop(context);
                _goToOnboarding(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text("Зарегистрироваться"),
              onTap: () {
                Navigator.pop(context);
                _goToOnboarding(context);
              },
            ),
            const Spacer(),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.4,
          ),
          itemCount: fakeMachines.length,
          itemBuilder: (context, index) {
            final machine = fakeMachines[index];

            return GestureDetector(
              onTap: () => _showAuthRequired(context),
              child: MachineCard(
                machine: machine,
                onActionPressed: (_) => _showAuthRequired(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

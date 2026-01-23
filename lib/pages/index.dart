import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/components/title_app_design.dart';
import 'package:equip_sight/pages/help_page.dart';
import 'package:equip_sight/pages/onboarding.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/machine_card.dart';
import '../model/model.dart';
import '../providers/machine_provider.dart';
import '../providers/notification_provider.dart';
import 'notifications_page.dart';
import 'profil_page.dart';

class IndexPage extends StatefulWidget {
  static const String id = 'Index';
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  Timer? _timer;
  bool _isRefreshing = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndInitialize();
  }

  void _checkAuthAndInitialize() async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, OnboardingPage.id);
        return;
      }
    }

    await FirebaseAuth.instance.currentUser!.getIdToken(true);

    setState(() {
      _isCheckingAuth = false;
    });

    _startTimer();
    _initializeData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeData() async {
    try {
      final userProvider = context.read<UserProvider>();
      final utilisateur = userProvider.currentUser;
      if (utilisateur == null) return;

      final dormRef = userProvider.dormRef;
      if (dormRef == null) throw Exception('DormRef introuvable');

      await context.read<MachineProvider>().loadMachines(dormRef);
    } catch (e, stack) {
      debugPrint('Erreur lors de l’initialisation des données: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {});
  }

  Future<void> _refreshData() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;

      if (user == null || user.dormPath == null) {
        throw Exception('DormPath introuvable');
      }

      await context.read<MachineProvider>().loadMachines(
        user.dormPath as DocumentReference<Object?>,
      );

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Данные обновлены'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _startMachine(Machine machine) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final userProvider = context.read<UserProvider>();

      await context.read<MachineProvider>().demarrerMachine(
        machineId: machine.id,
        userProvider: userProvider,
        notificationProvider: context.read<NotificationProvider>(),
        preferencesProvider: context.read<PreferencesProvider>(),
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${machine.nom} démarrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _releaseMachine(Machine machine) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final machineProvider = context.read<MachineProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final userProvider = context.read<UserProvider>();

      await machineProvider.libererMachine(
        machineId: machine.id,
        userProvider: userProvider,
        notificationProvider: notificationProvider,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${machine.nom} освобождена'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMachineAction(Machine machine) {
    switch (machine.statut) {
      case MachineStatus.libre:
        _showStartDialog(machine);
        break;
      case MachineStatus.termine:
        _showReleaseDialog(machine);
        break;
      case MachineStatus.occupe:
        _showMachineInfo(machine);
        break;
    }
  }

  void _showStartDialog(Machine machine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Запустить машину'),
          content: Text('Запустить ${machine.nom}? (40 минут)'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Запустить'), // Запустить
              onPressed: () async {
                Navigator.of(context).pop();
                await _startMachine(machine);
              },
            ),
          ],
        );
      },
    );
  }

  void _showReleaseDialog(Machine machine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Освободить машину'),
          content: Text('Освободить ${machine.nom}?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Освободить'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _releaseMachine(machine);
              },
            ),
          ],
        );
      },
    );
  }

  void _showMachineInfo(Machine machine) {
    final machineProvider = context.read<MachineProvider>();
    final userProvider = context.read<UserProvider>();

    final dormPath = userProvider.currentUser?.dormPath;
    if (dormPath == null) return;

    final remainingTime = machineProvider.getRemainingTime(
      machineId: machine.id,
      dormPath: dormPath,
    );

    final hasActiveTimer = machineProvider.hasActiveTimer(
      machineId: machine.id,
      dormPath: dormPath,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(machine.nom),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статус: Занята',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (remainingTime != null)
                Text(
                  'Осталось времени: $remainingTime минут',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              if (remainingTime == null && hasActiveTimer)
                Text(
                  'Таймер активен, но время недоступно',
                  style: TextStyle(fontSize: 14, color: Colors.orange),
                ),
              if (!hasActiveTimer)
                Text(
                  'Нет активного таймера',
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              SizedBox(height: 10),
              Text(
                'Пользователь: ${machine.utilisateurActuel ?? 'Неизвестно'}',
              ), // Пользователь
              SizedBox(height: 10),
              Text(
                '⏰ Таймер независимый и постоянный',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Закрыть'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    Navigator.pushNamed(context, NotificationsPage.id);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход из системы'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _performLogout();
                Navigator.pushNamed(context, OnboardingPage.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, OnboardingPage.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Color(0xFF459380),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Проверка подключения...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF459380),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const TitleAppDesign(textTitle: 'EquipSight'),
        actions: [
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshData,
                  tooltip: 'Обновить',
                ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotifications,
                tooltip: 'Уведомления',
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          notificationProvider.unreadCount > 9
                              ? '9+'
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
        backgroundColor: const Color(0xFF459380),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: Consumer<MachineProvider>(
        builder: (context, machineProvider, child) {
          if (machineProvider.isLoading && !_isRefreshing) {
            return _buildLoadingScreen();
          }

          if (machineProvider.machines.isEmpty) {
            return _buildEmptyScreen();
          }

          return _buildBody(machineProvider.machines, machineProvider);
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.currentUser;
                    final hasUserPhoto =
                        user?.photoURL != null && user!.photoURL!.isNotEmpty;

                    return UserAccountsDrawerHeader(
                      accountName: Text(
                        user?.displayName ?? user?.email ?? 'Пользователь',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      accountEmail: user != null
                          ? Text(user.email)
                          : const Text('Не подключен'),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: hasUserPhoto
                            ? NetworkImage(user.photoURL!)
                            : null,
                        backgroundColor: Colors.blueGrey[300],
                        child: hasUserPhoto
                            ? null
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                      decoration: const BoxDecoration(color: Color(0xFF459380)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Мой профиль'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, ProfilePage.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Помощь'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, HelpPage.id);
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 100.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выход',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Удалить аккаунт',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteAccountDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Machine> machines, MachineProvider machineProvider) {
    return Container(
      color: const Color(0xFF459380),
      child: Column(
        children: [
          _buildStatsHeader(machines, machineProvider),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildMachinesGrid(machines, machineProvider),
            ),
          ),
          // В классе _IndexPageState, в методе build, добавь:
          /*  FloatingActionButton(
            onPressed: () async {
              // Простой тест уведомлений
              await SimpleBackgroundService.showNotification(
                title: 'Test Machine',
                body: 'Timer démarré pour Machine 1',
              );

              // Запланированный тест (30 секунд)
              await SimpleBackgroundService.scheduleNotification(
                title: '⏰ Rappel',
                body: 'Vérifiez votre machine',
                delay: Duration(seconds: 30),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifications test envoyées!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Icon(Icons.notifications),
            backgroundColor: Color(0xFF459380),
          ),*/
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
    List<Machine> machines,
    MachineProvider machineProvider,
  ) {
    final machinesLibres = machines
        .where((m) => m.statut == MachineStatus.libre)
        .length;
    final machinesOccupees = machines
        .where((m) => m.statut == MachineStatus.occupe)
        .length;
    final machinesTerminees = machines
        .where((m) => m.statut == MachineStatus.termine)
        .length;
    final activeTimers = machineProvider.activeTimers
        .where((t) => t.isActive)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Всего',
                machines.length.toString(),
                Icons.local_laundry_service,
              ),
              _buildStatItem(
                'Свободны',
                machinesLibres.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatItem(
                'Заняты',
                machinesOccupees.toString(),
                Icons.timer,
                color: Colors.orange,
              ),
              _buildStatItem(
                'Завершены',
                machinesTerminees.toString(),
                Icons.done_all,
                color: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 10),
          if (activeTimers > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '$activeTimers активный(е) таймер(ы)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon, {
    Color color = Colors.blue,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Загрузка машин...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_laundry_service,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет доступных машин',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  Widget _buildMachinesGrid(
    List<Machine> machines,
    MachineProvider machineProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.4,
        ),
        itemCount: machines.length,
        itemBuilder: (context, index) {
          final machine = machines[index];
          final userProvider = context.read<UserProvider>();
          final dormPath = userProvider.currentUser?.dormPath;

          final remainingTime = dormPath == null
              ? null
              : machineProvider.getRemainingTime(
                  machineId: machine.id,
                  dormPath: dormPath,
                );

          final machineWithRealTime = Machine(
            id: machine.id,
            nom: machine.nom,
            emplacement: machine.emplacement,
            statut: machine.statut,
            tempsRestant: remainingTime,
            utilisateurActuel: machine.utilisateurActuel,
          );

          return MachineCard(
            machine: machineWithRealTime,
            onActionPressed: _handleMachineAction,
          );
        },
      ),
    );
  }
}

Future<void> deleteAccount(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Пользователь не найден'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String uid = user.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    await user.delete();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅ Аккаунт успешно удален'),
        backgroundColor: Colors.green,
      ),
    );

    navigator.pushReplacementNamed(OnboardingPage.id);
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '⚠ Для удаления аккаунта необходимо заново войти в систему',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка Firebase: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Ошибка при удалении аккаунта: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: const Text(
          'Вы уверены, что хотите удалить свой аккаунт и все данные? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              await deleteAccount(context);
            },
          ),
        ],
      );
    },
  );
}

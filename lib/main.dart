import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:equip_sight/pages/forgot_password.dart';
import 'package:equip_sight/pages/help_page.dart';
import 'package:equip_sight/pages/index.dart';
import 'package:equip_sight/pages/login.dart';
import 'package:equip_sight/pages/notifications_page.dart';
import 'package:equip_sight/pages/profil_page.dart';
import 'package:equip_sight/pages/registration.dart';
import 'package:equip_sight/pages/settings_page.dart';
import 'package:equip_sight/providers/machine_provider.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/role_router.dart';
import 'pages/home_locked.dart';
import 'pages/onboarding.dart';
import 'services/local_notification_service.dart';

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LocalNotificationService.showNotification(
    title: message.notification?.title ?? "Уведомление",
    body: message.notification?.body ?? "",
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
  await initFCM();
  await FirebaseMessaging.instance.subscribeToTopic("laundry_lens_test");
  await AndroidAlarmManager.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();

  //await syncMachinesToFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationService.showNotification(
        title: message.notification?.title ?? "Уведомление",
        body: message.notification?.body ?? "",
      );
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MachineProvider(),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider()..loadPreferences(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider(), lazy: false),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          OnboardingPage.id: (context) => OnboardingPage(),
          Login.id: (context) => Login(),
          Registration.id: (context) => Registration(),
          IndexPage.id: (context) => IndexPage(),
          NotificationsPage.id: (context) => NotificationsPage(),
          SettingsPage.id: (context) => SettingsPage(),
          ProfilePage.id: (context) => ProfilePage(),
          HomeLockedPage.id: (_) => const HomeLockedPage(),
          HelpPage.id: (context) => HelpPage(),
          ForgotPasswordPage.id: (context) => ForgotPasswordPage(),
        },

        theme: ThemeData(
          primaryColor: Color(0xFF459380),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.green,
          ).copyWith(secondary: Colors.orange),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null &&
        userProvider.role != null &&
        userProvider.universityId != null &&
        userProvider.countryId != null &&
        userProvider.cityId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateByRole(
          context,
          userProvider.role,
          universityId: userProvider.universityId,
          countryId: userProvider.countryId,
          cityId: userProvider.cityId,
          dormId: userProvider.dormId,
        );
      });

      return const SizedBox();
    }

    return HomeLockedPage();
  }
}

Future<void> initFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await FirebaseMessaging.instance.subscribeToTopic("laundry_lens_test");
}

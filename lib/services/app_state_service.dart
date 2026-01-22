import 'package:flutter/material.dart';

// Сервис для отслеживания состояния приложения
// Service de suivi de l'état de l'application
class AppStateService {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  AppLifecycleState _currentState = AppLifecycleState.resumed;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppLifecycleState get currentState => _currentState;
  set currentState(AppLifecycleState state) {
    _currentState = state;
  }

  // Геттер: Приложение активно
  // Getter: Application active
  bool get isAppActive => _currentState == AppLifecycleState.resumed;

  // Геттер: Приложение неактивно
  // Getter: Application inactive
  bool get isAppInactive => _currentState == AppLifecycleState.inactive;

  // Геттер: Приложение приостановлено
  // Getter: Application mise en pause
  bool get isAppPaused => _currentState == AppLifecycleState.paused;

  // Геттер: Приложение в фоновом режиме
  // Getter: Application en arrière-plan
  bool get isAppInBackground => isAppInactive || isAppPaused;
}
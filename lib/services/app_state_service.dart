import 'package:flutter/material.dart';

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

  bool get isAppActive => _currentState == AppLifecycleState.resumed;
  bool get isAppInactive => _currentState == AppLifecycleState.inactive;
  bool get isAppPaused => _currentState == AppLifecycleState.paused;
  bool get isAppInBackground => isAppInactive || isAppPaused;
}

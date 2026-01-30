import 'package:flutter/material.dart';

enum MenuAction { parametres, profil, aide }

extension MenuActionExtension on MenuAction {
  String get label {
    if (this case MenuAction.parametres) {
      return 'Настройки';
    } else if (this case MenuAction.profil) {
      return 'Профиль';
    } else if (this case MenuAction.aide) {
      return 'Помощь';
    } else {
      return '';
    }
  }

  IconData get icon {
    switch (this) {
      case MenuAction.parametres:
        return Icons.settings;
      case MenuAction.profil:
        return Icons.person;
      case MenuAction.aide:
        return Icons.help;
      // ignore: unreachable_switch_default
      default:
        return Icons.info;
    }
  }
}

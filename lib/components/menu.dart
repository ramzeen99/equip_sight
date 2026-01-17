import 'package:flutter/material.dart';

// FR : Définir les options du menu
// RU : Определение пунктов меню
enum MenuAction { parametres, profil, aide }

// FR : Extension pour gérer les labels affichés dans l'UI
// RU : Расширение для управления отображаемыми подписями
extension MenuActionExtension on MenuAction {

  // FR : Texte affiché pour chaque option du menu (UI → traduit en russe)
  // RU : Текст, отображаемый для каждого пункта меню (интерфейс → на русском)
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

  // FR : Icône associée à chaque option (ne doit pas être traduit)
  // RU : Иконка для каждого пункта (не переводится)
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

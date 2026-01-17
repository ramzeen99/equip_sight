import 'package:flutter/material.dart';
import 'package:laundry_lens/constants.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// FR : Widget pour afficher le titre animé de l'application
// RU : Виджет для отображения анимированного названия приложения
class TitleAppDesign extends StatelessWidget {
  const TitleAppDesign({required this.textTitle, super.key});

  // FR : Texte du titre (sera passé depuis l’extérieur)
  // RU : Текст заголовка (передаётся как параметр)
  final String textTitle;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      // FR : Style par défaut du texte
      // RU : Стиль текста по умолчанию
      style: titreStyle,

      child: AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            textTitle,
            // FR : Le texte sera traduit en russe directement quand tu appelleras ce widget
            // RU : Текст будет на русском, когда ты передашь его при использовании виджета

            textStyle: titreStyle,
            colors: colorizeColors, // FR : Couleurs pour l’animation
            // RU : Цвета анимации
          ),
        ],

        isRepeatingAnimation: true,  // FR : L’animation tourne en boucle
        // RU : Анимация повторяется бесконечно

        repeatForever: true,         // FR : Animation sans fin
        // RU : Бесконечная анимация
      ),
    );
  }
}

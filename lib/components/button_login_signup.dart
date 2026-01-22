import 'package:flutter/material.dart';

// FR : Bouton réutilisable pour connexion / inscription
// RU : Многоразовая кнопка для входа / регистрации
class ButtonLoginSignup extends StatelessWidget {
  const ButtonLoginSignup({
    required this.onPressed,
    required this.colorButton,
    required this.sizeButton,
    required this.textButton,
    required this.colorText,
    super.key,
  });

  // FR : Texte du bouton (déjà fourni en paramètre)
  // RU : Текст кнопки (передаётся как параметр)
  final String textButton;

  // FR : Couleur du bouton
  // RU : Цвет кнопки
  final Color colorButton;

  // FR : Taille du texte
  // RU : Размер текста
  final double sizeButton;

  // FR : Couleur du texte
  // RU : Цвет текста
  final Color colorText;

  // FR : Fonction appelée lors du clic
  // RU : Функция, вызываемая при нажатии
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20.0, right: 20.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(colorButton),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
          ),
          //
        ),
        child: Text(
          textButton, // FR : Le texte sera passé en russe depuis l'appel
          // RU : Текст будет на русском, когда ты передашь его при вызове
          style: TextStyle(
            fontSize: sizeButton,
            fontFamily: 'Momo',
            color: colorText,
          ), //
        ),
      ),
    );
  }
}

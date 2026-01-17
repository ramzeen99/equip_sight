import 'package:flutter/material.dart';
import 'package:laundry_lens/constants.dart';

// FR : Champ de mot de passe réutilisable
// RU : Многоразовое поле для ввода пароля
class PasswordField extends StatelessWidget {
  const PasswordField({required this.onChanged, super.key});

  // FR : Fonction appelée lorsque le texte change
  // RU : Функция, вызываемая при изменении текста
  final ValueChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        obscureText: true, // FR : Masquer le texte
        // RU : Скрывать вводимый текст (пароль)
        style: TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: 'ПАРОЛЬ', // FR : "Mot de passe"
          // RU : Подсказка "Пароль"
          labelText: 'ПАРОЛЬ', // FR : Étiquette "Mot de passe"
          // RU : Метка "Пароль"
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

// FR : Champ email réutilisable
// RU : Многоразовое поле для ввода email
class EmailField extends StatelessWidget {
  const EmailField({required this.onChanged, super.key, this.hintText});

  // FR : Fonction appelée lors d'un changement de texte
  // RU : Функция, вызываемая при изменении текста
  final ValueChanged onChanged;

  // FR : Texte d'indice optionnel
  // RU : Необязательная подсказка
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: hintText ?? 'EMAIL', // FR : Peut être personnalisé
          // RU : Можно передать своё значение
          labelText: 'EMAIL', // FR : Étiquette "Email"
          // RU : Метка "Email"
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

// FR : Champ nom réutilisable
// RU : Многоразовое поле для ввода имени
class NameField extends StatelessWidget {
  const NameField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        //controller: controller,
        keyboardType: TextInputType.text,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: 'ИМЯ', // FR : "Nom" / RU : "Имя"
          labelText: 'ИМЯ', // FR : "Nom" / RU : "Имя"
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}




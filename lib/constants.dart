import 'package:flutter/material.dart';

const shadow = Shadow(
  color: Color.fromRGBO(0, 0, 0, 0.3),
  blurRadius: 4,
  offset: Offset(3, 3),
);
const titreStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 25.0,
  fontWeight: FontWeight.w900,
  color: Color(0xFFFFFFFF),
  shadows: [shadow],
);

const sousTitreStyle = TextStyle(
  fontFamily: 'Momo',
  fontWeight: FontWeight.w700,
  fontSize: 16.0,
  shadows: [shadow],
  color: Color(0xFFFFFFFF),
);
const colorizeColors = [
  Color(0xFFFFFFFF),
  Color(0xFF1E40AF),
  Color(0xFF374151),
  Color(0xFFEA580C),
];
const int totalTimeMinutes = 40;
const kTextFieldDecoration = InputDecoration(
  hintText: 'Введите значение',
  hintStyle: TextStyle(color: Colors.white24),
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blue, width: 4.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);
const Map<String, String> firebaseErrorMessages = {
  'user-not-found': 'Пользователь с таким email не найден.',
  'wrong-password': 'Неверный пароль.',
  'too-many-requests': 'Слишком много попыток. Попробуйте позже.',
  'user-disabled': 'Эта учетная запись отключена.',

  'email-already-in-use': 'Этот адрес электронной почты уже используется.',
  'invalid-email': 'Неверный адрес электронной почты.',
  'operation-not-allowed': 'Регистрация по email не включена.',
  'weak-password': 'Пароль слишком слабый (минимум 6 символов).',

  'network-request-failed': 'Ошибка подключения. Проверьте интернет.',
  'requires-recent-login': 'Сессия истекла. Войдите снова.',
};

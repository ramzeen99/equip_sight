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
  hintText: 'Введите значение', // Перевод: Enter a value
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
// Ajoute ces constantes pour les messages d'erreur / Добавить эти константы для сообщений об ошибках
const Map<String, String> firebaseErrorMessages = {
  // Erreurs de connexion / Ошибки входа
  'user-not-found': 'Пользователь с таким email не найден.', // No user found with this email
  'wrong-password': 'Неверный пароль.', // Wrong password
  'too-many-requests': 'Слишком много попыток. Попробуйте позже.', // Too many attempts. Try again later
  'user-disabled': 'Эта учетная запись отключена.', // This account has been disabled

  // Erreurs d'inscription / Ошибки регистрации
  'email-already-in-use': 'Этот адрес электронной почты уже используется.', // This email address is already in use
  'invalid-email': 'Неверный адрес электронной почты.', // Invalid email address
  'operation-not-allowed': 'Регистрация по email не включена.', // Email registration is not enabled
  'weak-password': 'Пароль слишком слабый (минимум 6 символов).', // Password is too weak (minimum 6 characters)

  // Erreurs générales / Общие ошибки
  'network-request-failed': 'Ошибка подключения. Проверьте интернет.', // Connection error. Check your internet
  'requires-recent-login': 'Сессия истекла. Войдите снова.', // Session expired. Log in again
};
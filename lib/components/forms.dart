import 'package:equip_sight/constants.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({required this.onChanged, super.key});

  final ValueChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        obscureText: true,
        style: TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: 'ПАРОЛЬ',
          labelText: 'ПАРОЛЬ',
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({required this.onChanged, super.key, this.hintText});

  final ValueChanged onChanged;

  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        keyboardType: TextInputType.emailAddress,
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: hintText ?? 'ЭЛЕКТРОННАЯ ПОЧТА',
          labelText: 'ЭЛЕКТРОННАЯ ПОЧТА',
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class NameField extends StatelessWidget {
  const NameField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        keyboardType: TextInputType.text,
        autocorrect: false,
        enableSuggestions: false,
        onChanged: onChanged,
        decoration: kTextFieldDecoration.copyWith(
          hintText: 'ИМЯ',
          labelText: 'ИМЯ',
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

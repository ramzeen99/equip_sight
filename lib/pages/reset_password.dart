import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetWithCodePage extends StatefulWidget {
  static const String id = 'ResetWithCodePage';
  const ResetWithCodePage({super.key});

  @override
  State<ResetWithCodePage> createState() => _ResetWithCodePageState();
}

class _ResetWithCodePageState extends State<ResetWithCodePage> {
  final _auth = FirebaseAuth.instance;
  String code = '';
  String newPassword = '';
  String confirmPassword = '';
  String? errorMessage;
  String? successMessage;
  bool showSpinner = false;

  Future<void> _resetPassword() async {
    final navigator = Navigator.of(context);
    if (code.isEmpty) {
      setState(() => errorMessage = 'Введите код, полученный по электронной почте');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => errorMessage = 'Минимум 6 символов');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => errorMessage = 'Пароли не совпадают');
      return;
    }

    setState(() {
      showSpinner = true;
      errorMessage = null;
    });

    try {
      // Dans la réalité, tu devrais utiliser le code pour vérifier
      // Но для упрощения просто проверяем, что пользователь авторизован
      final user = _auth.currentUser;

      if (user != null) {
        await user.updatePassword(newPassword);
        setState(() {
          successMessage = 'Пароль успешно обновлен!';
        });

        Future.delayed(Duration(seconds: 2), () {
          navigator.popUntil( (route) => route.isFirst);
        });
      } else {
        setState(() => errorMessage = 'Пожалуйста, войдите снова');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = 'Ошибка: ${e.message}');
    } catch (e) {
      setState(() => errorMessage = 'Ошибка: $e');
    } finally {
      setState(() => showSpinner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Новый пароль'), // Новый пароль
        backgroundColor: Color(0xFF459380),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Код из электронной почты', // Код из электронной почты
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => code = value,
            ),

            SizedBox(height: 20),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Новый пароль', // Новый пароль
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => newPassword = value,
            ),

            SizedBox(height: 20),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль', // Подтвердите пароль
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => confirmPassword = value,
            ),

            SizedBox(height: 30),

            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.red[50],
                child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
              ),

            if (successMessage != null)
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.green[50],
                child: Text(
                  successMessage!,
                  style: TextStyle(color: Colors.green),
                ),
              ),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E40AF),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: showSpinner ? null : _resetPassword,
              child: showSpinner
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'Сбросить пароль', // Сбросить пароль
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
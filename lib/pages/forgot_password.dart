import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:laundry_lens/components/title_app_design.dart';
import 'package:laundry_lens/components/button_login_signup.dart';
import 'package:laundry_lens/components/forms.dart';
import 'package:laundry_lens/pages/login.dart';

// FR : Page de récupération du mot de passe
// RU : Страница восстановления пароля
class ForgotPasswordPage extends StatefulWidget {
  static const String id = 'ForgotPassword';
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  bool emailSent = false;
  String email = '';
  String? errorMessage;
  bool showError = false;
  String? successMessage;

  // FR : Méthode pour afficher l'erreur
  // RU : Метод для отображения ошибки
  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
      successMessage = null;
    });
  }

  // FR : Méthode pour afficher le succès
  // RU : Метод для отображения успешного сообщения
  void _showSuccess(String message) {
    setState(() {
      successMessage = message;
      emailSent = true;
      showError = false;
    });
  }

  // FR : Traduire les erreurs Firebase en texte
  // RU : Перевод ошибок Firebase в текст
  String _translateFirebaseError(String errorCode) {
    const Map<String, String> firebaseErrorMessages = {
      'user-not-found': 'Пользователь с этим email не найден.', // Aucun utilisateur trouvé avec cet email
      'invalid-email': 'Неверный адрес электронной почты.', // Adresse email invalide
      'user-disabled': 'Этот аккаунт был отключен.', // Ce compte a été désactivé
      'too-many-requests': 'Слишком много попыток. Попробуйте позже.', // Trop de tentatives
      'network-request-failed': 'Ошибка подключения. Проверьте интернет.', // Erreur de connexion
    };

    return firebaseErrorMessages[errorCode] ??
        'Произошла ошибка. Пожалуйста, попробуйте снова.'; // Une erreur est survenue
  }

  // FR : Valider l'email
  // RU : Проверка email
  bool _validateEmail() {
    if (email.isEmpty) {
      _showError('Пожалуйста, введите ваш email'); // Veuillez entrer votre adresse email
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Пожалуйста, введите корректный email'); // Veuillez entrer une adresse email valide
      return false;
    }

    return true;
  }

  // FR : Envoyer l'email de réinitialisation
  // RU : Отправка письма для сброса пароля
  Future<void> _sendPasswordResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_validateEmail()) return;

    setState(() {
      showSpinner = true;
      showError = false;
      successMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _showSuccess('Письмо для сброса пароля отправлено на $email'); // Un email de réinitialisation a été envoyé
      //print('✅ Email envoyé à: $email');

      setState(() {
        showSpinner = false;
      });
    } on FirebaseAuthException catch (e) {
      String message = _translateFirebaseError(e.code);
      _showError(message);
      //print('🔥 Ошибка Firebase: ${e.code} - ${e.message}');

      setState(() {
        showSpinner = false;
        emailSent = false;
      });
    } catch (e) {
      _showError('Произошла непредвиденная ошибка'); // Une erreur inattendue est survenue
      //print('❌ Ошибка сброса пароля: $e');

      setState(() {
        showSpinner = false;
        emailSent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF459380),
      appBar: AppBar(
        backgroundColor: Color(0xFF459380),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // FR : Revenir en arrière
            // RU : Вернуться назад
          },
        ),
        title: Text(
          'Восстановление пароля', // FR : Récupération mot de passe
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 20.0),

                // FR : TITRE
                // RU : ЗАГОЛОВОК
                TitleAppDesign(textTitle: 'СБРОС'),
                TitleAppDesign(textTitle: 'ПАРОЛЯ'),

                SizedBox(height: 20.0),

                // FR : ICÔNE
                // RU : ИКОНКА
                Icon(Icons.lock_reset, size: 80, color: Colors.white),

                SizedBox(height: 30.0),

                // FR : MESSAGE EXPLICATIF
                // RU : Поясняющее сообщение
                Text(
                  'Введите ваш email, и мы отправим ссылку для сброса пароля.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 30.0),

                // FR : MESSAGE D'ERREUR
                // RU : Сообщение об ошибке
                if (showError && errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // FR : MESSAGE DE SUCCÈS
                // RU : Сообщение об успешной отправке
                if (successMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            successMessage!,
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 20.0),

                // FR : CHAMP EMAIL
                // RU : Поле ввода email (если письмо не отправлено)
                if (!emailSent)
                  Column(
                    children: [
                      EmailField(
                        hintText: 'Введите ваш email', // FR : Entrez votre email
                        onChanged: (value) {
                          setState(() {
                            email = value;
                            if (showError) showError = false;
                          });
                        },
                      ),
                      SizedBox(height: 30.0),

                      // FR : BOUTON ENVOYER
                      // RU : КНОПКА ОТПРАВИТЬ
                      SizedBox(
                        width: double.infinity,
                        child: ButtonLoginSignup(
                          textButton: 'ОТПРАВИТЬ ССЫЛКУ', // ENVOYER LE LIEN
                          colorButton: Color(0xFF1E40AF),
                          sizeButton: 20.0,
                          colorText: Colors.white,
                          onPressed: _sendPasswordResetEmail,
                        ),
                      ),
                    ],
                  ),

                // FR : MESSAGE APRÈS ENVOI RÉUSSI
                // RU : Сообщение после успешной отправки
                if (emailSent)
                  Column(
                    children: [
                      Icon(
                        Icons.mark_email_read,
                        size: 30,
                        color: Colors.green,
                      ),
                      SizedBox(height: 20),

                      // FR : INSTRUCTIONS
                      // RU : ИНСТРУКЦИЯ
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '📧 Проверьте вашу почту', // Vérifiez votre boîte mail
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '1. Откройте письмо, которое мы отправили\n'
                                  '2. Нажмите на ссылку для сброса пароля\n'
                                  '3. Выберите новый пароль\n'
                                  '4. Войдите с новым паролем',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // FR : BOUTON RETOUR À LA CONNEXION
                      // RU : КНОПКА ВОЙТИ
                      SizedBox(
                        width: double.infinity,
                        child: ButtonLoginSignup(
                          textButton: 'ВОЙТИ', // RETOUR À LA CONNEXION
                          colorButton: Colors.green,
                          sizeButton: 15.0,
                          colorText: Colors.white,
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Login.id,
                                  (route) => false, // FR : Supprime toutes les routes
                              // RU : Удалить все маршруты
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      // FR : BOUTON RÉESSAYER
                      // RU : КНОПКА ПОВТОРИТЬ
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            emailSent = false;
                            email = '';
                            successMessage = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white),
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                        ),
                        child: Text('ПОВТОРИТЬ'), // RÉESSAYER
                      ),
                    ],
                  ),

                SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

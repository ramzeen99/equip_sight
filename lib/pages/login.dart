import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:laundry_lens/components/button_login_signup.dart';
import 'package:laundry_lens/components/forms.dart';
import 'package:laundry_lens/components/role_router.dart';
import 'package:laundry_lens/components/social_login_button.dart';
import 'package:laundry_lens/components/title_app_design.dart';
import 'package:laundry_lens/constants.dart';
import 'package:laundry_lens/pages/forgot_password.dart';
import 'package:laundry_lens/services/auth_service.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Login extends StatefulWidget {
  static const String id = 'Login';
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool showSpinner = false;
  late String email;
  late String password;
  String? errorMessage;
  bool showError = false;

  final ScrollController _scrollController = ScrollController();

  void _showError(String message) {
    setState(() {
      errorMessage = message;
      showError = true;
    });

    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showError = false;
        });
      }
    });
  }

  String _translateFirebaseError(String errorCode) {
    return firebaseErrorMessages[errorCode] ??
        'Произошла ошибка. Код: $errorCode';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF459380),
      appBar: AppBar(
        title: TitleAppDesign(textTitle: 'LAUNDRY LENS'),
        backgroundColor: Color(0xFF459380),
        centerTitle: true,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(flex: 1, child: SizedBox(height: 20)),

                      Column(
                        children: [
                          TitleAppDesign(textTitle: 'ДОБРО ПОЖАЛОВАТЬ'),
                          TitleAppDesign(textTitle: 'В LAUNDRY LENS'),
                        ],
                      ),

                      SizedBox(height: 20.0),

                      if (showError && errorMessage != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
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
                                IconButton(
                                  icon: Icon(Icons.close, size: 18),
                                  color: Colors.red,
                                  onPressed: () {
                                    setState(() {
                                      showError = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 20.0),

                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmailField(
                              onChanged: (value) {
                                email = value;
                                if (showError) {
                                  setState(() {
                                    showError = false;
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 16.0),
                            PasswordField(
                              onChanged: (value) {
                                password = value;
                                if (showError) {
                                  setState(() {
                                    showError = false;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ButtonLoginSignup(
                              textButton: 'Войти',
                              colorButton: Color(0xFF1E40AF),
                              sizeButton: 40.0,
                              colorText: Colors.white,
                              onPressed: () async {
                                if (email.isEmpty || password.isEmpty) {
                                  _showError('Пожалуйста, заполните все поля');
                                  return;
                                }

                                setState(() {
                                  showSpinner = true;
                                  showError = false;
                                });

                                try {
                                  final authService = AuthService();
                                  try {
                                    final userData = await authService.signIn(
                                      email,
                                      password,
                                    );
                                    final role = userData['role'];
                                    saveFcmToken();
                                    if (context.mounted) {
                                      navigateByRole(
                                        context,
                                        role,
                                        universityId: userData['universityId'],
                                        dormId: userData['dormId'],
                                      );
                                    }
                                    setState(() {
                                      showSpinner = false;
                                    });
                                  } on FirebaseAuthException catch (e) {
                                    _showError(_translateFirebaseError(e.code));
                                    setState(() => showSpinner = false);
                                  } catch (e) {
                                    _showError(e.toString());
                                    setState(() => showSpinner = false);
                                  }

                                  setState(() {
                                    showSpinner = false;
                                  });
                                } on FirebaseAuthException catch (e) {
                                  String message = _translateFirebaseError(
                                    e.code,
                                  );
                                  _showError(message);

                                  setState(() {
                                    showSpinner = false;
                                  });
                                } catch (e) {
                                  _showError('Произошла непредвиденная ошибка');
                                  setState(() {
                                    showSpinner = false;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 20),

                          Text(
                            'Или войти с помощью',
                            style: TextStyle(color: Colors.white70),
                          ),

                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SocialLoginButton(
                                asset: 'images/google.png',
                                onTap: () async {
                                  setState(() => showSpinner = true);
                                  try {
                                    final authService = AuthService();
                                    final userCredential = await authService
                                        .signInWithGoogle();

                                    final user = userCredential.user;
                                    if (user != null && context.mounted) {
                                      final uid = user.uid;

                                      final userDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(uid)
                                          .get();

                                      if (!userDoc.exists) {
                                        throw Exception(
                                          'Utilisateur non trouvé',
                                        );
                                      }

                                      final userData = userDoc.data()!;
                                      final role = userData['role'];

                                      saveFcmToken();

                                      if (context.mounted) {
                                        navigateByRole(
                                          context,
                                          role,
                                          universityId:
                                              userData['universityId'],
                                          dormId: userData['dormId'],
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    _showError(e.toString());
                                  }
                                  setState(() => showSpinner = false);
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    ForgotPasswordPage.id,
                                  );
                                },
                                child: Text(
                                  'Забыли пароль?',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 30.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Нет аккаунта?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      ' Регистрация',
                                      style: sousTitreStyle.copyWith(
                                        color: Colors.lightBlueAccent,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.lightBlueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

void saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': fcmToken,
    });
  }
}

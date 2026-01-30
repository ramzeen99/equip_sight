import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/components/button_login_signup.dart';
import 'package:equip_sight/components/forms.dart';
import 'package:equip_sight/components/role_router.dart';
import 'package:equip_sight/components/title_app_design.dart';
import 'package:equip_sight/constants.dart';
import 'package:equip_sight/model/user_model.dart' as prefix0;
import 'package:equip_sight/pages/login.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

class Registration extends StatefulWidget {
  static const String id = 'Registration';
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dropdown lists
  List<String> countries = [];
  List<String> cities = [];
  List<String> universities = [];
  List<String> dorms = [];

  // Dropdown selected values
  String? selectedCountry;
  String? selectedCity;
  String? selectedUniversity;
  String? selectedDorm;

  bool showSpinner = false;
  String email = '';
  String password = '';
  String name = '';
  String? errorMessage;
  bool showError = false;

  @override
  void initState() {
    super.initState();
    loadCountries();
  }

  Future<void> loadCountries() async {
    final snapshot = await _firestore.collection('countries').get();
    setState(() {
      countries = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> loadCities(String countryId) async {
    final snapshot = await _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .get();
    setState(() {
      cities = snapshot.docs.map((doc) => doc.id).toList();
      selectedCity = null;
      universities = [];
      selectedUniversity = null;
      dorms = [];
      selectedDorm = null;
    });
  }

  Future<void> loadUniversities(String countryId, String cityId) async {
    final snapshot = await _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .doc(cityId)
        .collection('universities')
        .get();
    setState(() {
      universities = snapshot.docs.map((doc) => doc.id).toList();
      selectedUniversity = null;
      dorms = [];
      selectedDorm = null;
    });
  }

  Future<void> loadDorms(
    String countryId,
    String cityId,
    String universityId,
  ) async {
    final snapshot = await _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .doc(cityId)
        .collection('universities')
        .doc(universityId)
        .collection('dorms')
        .get();
    setState(() {
      dorms = snapshot.docs.map((doc) => doc.id).toList();
      selectedDorm = null;
    });
  }

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
    const Map<String, String> firebaseErrorMessages = {
      'email-already-in-use': 'Этот адрес электронной почты уже используется.',
      'invalid-email': 'Неверный адрес электронной почты.',
      'operation-not-allowed': 'Регистрация по email не активирована.',
      'weak-password': 'Пароль слишком слабый (минимум 6 символов).',
      'network-request-failed': 'Ошибка соединения. Проверьте интернет.',
      'user-disabled': 'Эта учетная запись отключена.',
      'user-not-found': 'Пользователь не найден.',
      'wrong-password': 'Неверный пароль.',
      'too-many-requests': 'Слишком много попыток. Попробуйте позже.',
    };

    return firebaseErrorMessages[errorCode] ??
        'Произошла ошибка. Код: $errorCode';
  }

  bool _validateFields() {
    if (name.isEmpty || name.length < 2) {
      _showError('Пожалуйста, введите ваше имя (минимум 2 символа)');
      return false;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Пожалуйста, введите действительный адрес электронной почты');
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      _showError('Пароль должен содержать не менее 6 символов');
      return false;
    }

    if (selectedCountry == null ||
        selectedCity == null ||
        selectedUniversity == null ||
        selectedDorm == null) {
      _showError('Veuillez sélectionner Pays, Ville, Université et Dortoir');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF459380),
      appBar: AppBar(
        title: TitleAppDesign(textTitle: 'EquipSight'),
        backgroundColor: Color(0xFF459380),
        centerTitle: true,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 20.0),
                  TitleAppDesign(textTitle: 'ДОБРО ПОЖАЛОВАТЬ '),
                  TitleAppDesign(textTitle: 'В EquipSight'),

                  if (showError && errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
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
                            IconButton(
                              icon: Icon(Icons.close, size: 16),
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

                  NameField(
                    onChanged: (value) {
                      setState(() => name = value);
                    },
                  ),
                  SizedBox(height: 20.0),
                  EmailField(
                    onChanged: (value) {
                      setState(() => email = value);
                    },
                  ),
                  SizedBox(height: 20.0),
                  PasswordField(
                    onChanged: (value) {
                      setState(() => password = value);
                    },
                  ),

                  if (password.isNotEmpty) ...[
                    SizedBox(height: 10),
                    _buildPasswordStrengthIndicator(),
                    SizedBox(height: 10),
                  ],

                  SizedBox(height: 20),

                  _buildDropdown(
                    label: 'Страна',
                    value: selectedCountry,
                    items: countries,
                    onChanged: (val) {
                      setState(() {
                        selectedCountry = val;
                        if (val != null) loadCities(val);
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Город',
                    value: selectedCity,
                    items: cities,
                    onChanged: (val) {
                      setState(() {
                        selectedCity = val;
                        if (val != null && selectedCountry != null) {
                          loadUniversities(selectedCountry!, val);
                        }
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Университет',
                    value: selectedUniversity,
                    items: universities,
                    onChanged: (val) {
                      setState(() {
                        selectedUniversity = val;
                        if (val != null &&
                            selectedCountry != null &&
                            selectedCity != null) {
                          loadDorms(selectedCountry!, selectedCity!, val);
                        }
                      });
                    },
                  ),
                  _buildDropdown(
                    label: 'Общежитие',
                    value: selectedDorm,
                    items: dorms,
                    onChanged: (val) {
                      setState(() {
                        selectedDorm = val;
                      });
                    },
                  ),

                  SizedBox(height: 30.0),

                  SizedBox(
                    width: double.infinity,
                    child: ButtonLoginSignup(
                      textButton: 'ЗАРЕГИСТРИРОВАТЬСЯ',
                      colorButton: Color(0xFF1E40AF),
                      sizeButton: 25.0,
                      colorText: Colors.white,
                      onPressed: _registerUser,
                    ),
                  ),

                  SizedBox(height: 30.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Уже есть аккаунт?',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Login.id);
                        },
                        child: Text(
                          ' Войти',
                          style: sousTitreStyle.copyWith(
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.lightBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown builder
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
        ),
        initialValue: value,
        hint: Text("Выберите $label"),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _registerUser() async {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;

    setState(() {
      showSpinner = true;
      showError = false;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Ошибка пользователя");

      await user.updateDisplayName(name.trim());
      await user.reload();

      final appUser = prefix0.AppUser(
        id: user.uid,
        email: user.email!,
        displayName: name.trim(),
        countryId: selectedCountry,
        cityId: selectedCity,
        universityId: selectedUniversity,
        dormId: selectedDorm,
        emailVerified: user.emailVerified,
        role: 'user',
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      saveFcmToken();

      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.setCurrentUser(appUser);

      navigateByRole(
        context,
        appUser.role,
        universityId: appUser.universityId,
        countryId: appUser.countryId,
        cityId: appUser.cityId,
        dormId: appUser.dormId,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_translateFirebaseError(e.code));
    } catch (e) {
      _showError(e.toString());
      _showError('Ошибка при регистрации');
    } finally {
      if (mounted) {
        setState(() => showSpinner = false);
      }
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    Color color;
    String text;
    int strength = _calculatePasswordStrength(password);

    if (strength == 0) {
      color = Colors.red;
      text = 'Очень слабый';
    } else if (strength == 1) {
      color = Colors.orange;
      text = 'Слабый';
    } else if (strength == 2) {
      color = Colors.yellow[700]!;
      text = 'Средний';
    } else {
      color = Colors.green;
      text = 'Сильный';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сложность пароля: $text',
            style: TextStyle(color: color, fontSize: 14),
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: (strength + 1) / 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  int _calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score.clamp(0, 3);
  }
}

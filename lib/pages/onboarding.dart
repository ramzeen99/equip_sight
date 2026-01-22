import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:equip_sight/components/button_login_signup.dart';
import 'package:equip_sight/components/title_app_design.dart';
import 'package:equip_sight/constants.dart';
import 'package:equip_sight/pages/login.dart';
import 'package:equip_sight/pages/registration.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'index.dart';

class OnboardingPage extends StatefulWidget {
  static const String id = 'Onboarding';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animation;
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
      upperBound: 1.0,
    );

    animation = ColorTween(
      begin: Colors.white,
      end: Color(0xFF459380),
    ).animate(controller);
    controller.forward();

    controller.addListener(() {
      setState(() {});
    });

    _checkIfUserIsLoggedIn();
  }

  void _checkIfUserIsLoggedIn() async {
    if (_isCheckingAuth) return;

    setState(() {
      _isCheckingAuth = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Future.delayed(Duration(milliseconds: 1000));

    await userProvider.waitForInitialization();

    if (userProvider.isLoggedIn && userProvider.currentUser != null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, IndexPage.id);
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/background_onboarding.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          child: _isCheckingAuth
              ? _buildLoadingScreen()
              : _buildOnboardingContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Проверка подключения...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingContent() {
    return Container(
      padding: EdgeInsets.only(top: 20.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  SizedBox(child: TitleAppDesign(textTitle: 'EquipSight')),
                ],
              ),
            ),
            Center(
              child: DefaultTextStyle(
                style: sousTitreStyle,
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Экономь время, забудь о занятых машинках',
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  displayFullTextOnTap: true,
                  repeatForever: false,
                  totalRepeatCount: 1,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ButtonLoginSignup(
              textButton: 'Войти',
              colorButton: Color(0xFF1E40AF),
              sizeButton: 40.0,
              colorText: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, Login.id);
              },
            ),
            SizedBox(height: 20.0),
            ButtonLoginSignup(
              textButton: 'Регистрация',
              colorButton: Colors.transparent,
              sizeButton: 36.0,
              colorText: Color(0xFF1E40AF),
              onPressed: () {
                Navigator.pushNamed(context, Registration.id);
              },
            ),
            SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}

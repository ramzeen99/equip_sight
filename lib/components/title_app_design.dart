import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:equip_sight/constants.dart';
import 'package:flutter/material.dart';

class TitleAppDesign extends StatelessWidget {
  const TitleAppDesign({required this.textTitle, super.key});

  final String textTitle;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: titreStyle,
      child: AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            textTitle,
            textStyle: titreStyle,
            colors: colorizeColors,
          ),
        ],
        isRepeatingAnimation: true,
        repeatForever: true,
      ),
    );
  }
}

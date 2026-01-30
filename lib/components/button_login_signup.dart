import 'package:flutter/material.dart';

class ButtonLoginSignup extends StatelessWidget {
  const ButtonLoginSignup({
    required this.onPressed,
    required this.colorButton,
    required this.sizeButton,
    required this.textButton,
    required this.colorText,
    super.key,
  });

  final String textButton;

  final Color colorButton;

  final double sizeButton;

  final Color colorText;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20.0, right: 20.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(colorButton),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
          ),
          //
        ),
        child: Text(
          textButton,
          style: TextStyle(
            fontSize: sizeButton,
            fontFamily: 'Momo',
            color: colorText,
          ), //
        ),
      ),
    );
  }
}

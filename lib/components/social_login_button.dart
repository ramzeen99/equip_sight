import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Padding(padding: EdgeInsets.all(10), child: Image.asset(asset)),
      ),
    );
  }
}

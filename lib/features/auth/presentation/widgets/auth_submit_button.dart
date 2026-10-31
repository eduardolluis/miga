import 'package:flutter/material.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF52643D),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF465536),
        disabledForegroundColor: const Color(0xFFCDD2C7),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        minimumSize: const Size.fromHeight(58),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

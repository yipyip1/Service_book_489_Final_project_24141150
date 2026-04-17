import 'package:flutter/material.dart';

class BrutalistTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const BrutalistTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      // Focus and styling rules are handled automatically by 
      // the global BrutalistTheme applied in main.dart
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final TextInputType keyboardType;
  const MyTextField({Key? key, required this.controller, required this.label, required this.maxLength, required this.keyboardType,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLength: maxLength,
      controller: controller,
      decoration: InputDecoration(
          label: Text(label),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.0),
          )
      ),
    );
  }
}

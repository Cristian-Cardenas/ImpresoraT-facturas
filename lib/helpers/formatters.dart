import 'package:flutter/material.dart';

String formatCOP(double value) {
  return '\$${value.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

Widget buildFormTextField({
  required TextEditingController controller,
  required String labelText,
  required IconData prefixIcon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(prefixIcon),
    ),
    keyboardType: keyboardType,
    maxLines: maxLines,
  );
}

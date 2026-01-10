// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class Mytextformfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const Mytextformfield({
    super.key,
    required this.controller,
    required this.hintText,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        controller: controller,
        cursorColor: const Color(0xff050c20),
        decoration: InputDecoration(
          prefixIcon: leadingIcon,
          suffixIcon: trailingIcon,
          hintText: hintText,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xff050c20).withOpacity(.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff050c20)),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';

class LabelRequire extends StatelessWidget {
  final String labelText;

  const LabelRequire({required this.labelText, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          '*',
          style: TextStyle(color: ColorTheme.danger),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class LabelRequire extends StatelessWidget {
  final String labelText;
  final bool enabled;
  const LabelRequire(
      {required this.labelText, this.enabled = false, super.key});

  @override
  Widget build(BuildContext context) {
    print('[LabelRequire] ${labelText}: ${enabled}');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(labelText,
            style: TextStyle(
                color: !enabled ? ColorTheme.textPrimary : ColorTheme.grey400)),
        const SizedBox(
          width: 5,
        ),
        Text(
          '*',
          style: TextStyle(
              color: !enabled ? ColorTheme.danger : ColorTheme.grey400),
        ),
      ],
    );
  }
}

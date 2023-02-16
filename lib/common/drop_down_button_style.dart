import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class DropDownButtonStyle {
  InputDecoration getInputDecorationCustom(
      {Widget? labelText, String? hintText, bool enabled = false}) {
    return InputDecoration(
      label: labelText,
      labelStyle:
          MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
        return TextStyle(
          color: states.contains(MaterialState.error)
              ? ColorTheme.danger
              : ColorTheme.textPrimary,
          fontSize: 18,
        );
      }),
      hintText: hintText,
      hintStyle: CustomTextStyle.body2.copyWith(
        color: ColorTheme.grey400,
        fontSize: 16,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      floatingLabelStyle:
          MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
        return TextStyle(
          color: states.contains(MaterialState.error)
              ? ColorTheme.danger
              : ColorTheme.textPrimary,
          fontSize: 18,
        );
      }),
    );
  }
}

final dropDownButtonStyle = DropDownButtonStyle();

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class BottomNavyBarItem extends StatelessWidget {
  final void Function()? onPressed;
  final Widget icon;
  final String label;
  final bool? isDisabled;

  const BottomNavyBarItem(
      {required this.onPressed,
      required this.icon,
      required this.label,
      this.isDisabled = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    bool typeButton = label.toUpperCase().endsWith("Abort".toUpperCase()) ||
        label.toUpperCase().endsWith("Check out".toUpperCase()) ||
        label.toUpperCase().endsWith("Cancel".toUpperCase());
    bool redButton =
        label.toUpperCase().endsWith("Finish abort".toUpperCase()) ||
            label.toUpperCase().endsWith("Delete".toUpperCase());

    bool disabled = isDisabled != null && isDisabled == true;

    return Container(
      height: 40,
      child: TextButton.icon(
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.0),
            ),
          ),
          backgroundColor: MaterialStateProperty.all(redButton
              ? ColorTheme.danger
              : typeButton || disabled
                  ? ColorTheme.grey300
                  : ColorTheme.primary),
        ),
        onPressed: disabled ? () {} : onPressed,
        icon: icon,
        label: Text(
          label,
          style: CustomTextStyle.h6.copyWith(
              color: redButton
                  ? ColorTheme.white
                  : typeButton || disabled
                      ? ColorTheme.textPrimary
                      : ColorTheme.white,
              fontSize: 14),
        ),
      ),
    );
  }
}

class BottomSheet2 extends StatefulWidget {
  final double padding;
  final List<BottomNavyBarItem> buttonList;

  const BottomSheet2({this.padding = 5.0, required this.buttonList, super.key});

  @override
  State<BottomSheet2> createState() => _BottomSheet2State();
}

class _BottomSheet2State extends State<BottomSheet2> {
  Widget verticalLine = Container(
    height: 40,
    decoration: const BoxDecoration(
      border: Border.symmetric(
        vertical: BorderSide(
          width: 0.5,
          color: ColorTheme.white,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final widthScreen = MediaQuery.of(context).size.width;
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.buttonList.map(
          (item) {
            return (widget.buttonList.length == 1
                ? SizedBox(
                    width: widthScreen,
                    child: item,
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: ((widthScreen - widget.buttonList.length + 1) /
                            widget.buttonList.length),
                        child: item,
                      ),
                      if (item !=
                          widget.buttonList[widget.buttonList.length - 1])
                        verticalLine
                    ],
                  ));
          },
        ).toList(),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class MyDialog extends StatelessWidget {
  final Widget title;
  final Widget subTitle;
  final Widget func;
  final bool? buttonCancel;

  const MyDialog({
    required this.title,
    required this.subTitle,
    required this.func,
    this.buttonCancel = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(
              5.0,
            ),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
        contentPadding: EdgeInsets.zero,
        title: Center(child: title),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 16,
                ),
                Center(
                  child: subTitle,
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    if (buttonCancel == true)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: ColorTheme.grey300,
                          ),
                          child: Text(
                            "Cancel",
                            style: CustomTextStyle.h5.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: func,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

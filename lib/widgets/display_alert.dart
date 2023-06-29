import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

void openAlert({
  required BuildContext context,
  required String content,
  String? textButton,
}) {
  showDialog<void>(
    context: context,
    barrierColor: ColorTheme.backdrop,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(
                5.0,
              ),
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          contentPadding: EdgeInsets.zero,
          title: Center(
            child: Text(
              "Alert",
              style: CustomTextStyle.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorTheme.danger,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    content,
                    style: CustomTextStyle.h4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: ColorTheme.grey300,
                          ),
                          child: Text(
                            textButton ?? "OK",
                            style: CustomTextStyle.h4
                                .copyWith(color: ColorTheme.textPrimary),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> openAlertWithAction({
  required BuildContext context,
  required String title,
  required String content,
  required String textButton,
  required void Function()? action,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: ColorTheme.backdrop,
    builder: (BuildContext context) {
      return MyDialog(
        title: Text(
          title,
          style: CustomTextStyle.h4.copyWith(
            color: ColorTheme.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
        subTitle: Text(
          content,
          textAlign: TextAlign.center,
          style: CustomTextStyle.body1,
        ),
        func: ElevatedButton(
          onPressed: action,
          child: Text(textButton),
        ),
      );
    },
  );
}

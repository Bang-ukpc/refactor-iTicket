import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

void showAlertCheckVrnExits({required BuildContext context}) {
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
                  const Text(
                    'It is not possible to issue a PCN. The vehicle has already been issued the same Contravention type within 24 hours.',
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
                            "OK",
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

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

void showCircularProgressIndicator(
    {required BuildContext context, String? text}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: ColorTheme.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                text ?? 'Loading',
                style: CustomTextStyle.h3.copyWith(
                  fontFamily: 'Lato',
                  decoration: TextDecoration.none,
                  color: ColorTheme.white,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

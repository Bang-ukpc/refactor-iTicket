import 'package:flutter/material.dart';
import 'package:iWarden/common/dot.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

void displayLoading({required BuildContext context, required String text}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: ColorTheme.mask,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: CustomTextStyle.h3.copyWith(
                      decoration: TextDecoration.none,
                      color: ColorTheme.white,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 2),
                    child: const SpinKitThreeBounce(
                      color: ColorTheme.white,
                      size: 7,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showCircularProgressIndicator({required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      );
    },
  );
}

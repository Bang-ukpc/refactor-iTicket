import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:iWarden/theme/color.dart';
import 'dart:io';
import '../common/my_dialog.dart';
import '../configs/configs.dart';
import '../theme/text_theme.dart';

class TimeNTP with ChangeNotifier {
  DateTime? currentNtpTimeMs;
  void showDialogTime() {
    showDialog<void>(
      context: NavigationService.navigatorKey.currentContext!,
      barrierDismissible: true,
      barrierColor: ColorTheme.backdrop,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: MyDialog(
            buttonCancel: false,
            title: Text(
              "Waring",
              style: CustomTextStyle.h4.copyWith(
                  color: ColorTheme.danger, fontWeight: FontWeight.w600),
            ),
            subTitle: Text(
              "Please do not adjust the time to avoid any potential errors.",
              style: CustomTextStyle.h5.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            func: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorTheme.danger,
              ),
              child: Text(
                "Exit",
                style: CustomTextStyle.h5.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                exit(0);
              },
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> get() async {
    DateTime? now = await FlutterKronos.getNtpDateTime;
    if (now == null) {
      print('[NTP] null');
      showDialogTime();
      return;
    } else {
      print('[NTP] not null');
      return now;
    }
  }

  Future<void> sync() async {
    FlutterKronos.sync();
    notifyListeners();
  }
}

final timeNTP = TimeNTP();

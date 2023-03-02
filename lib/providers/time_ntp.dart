import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:iWarden/theme/color.dart';
import 'dart:io';
import '../common/my_dialog.dart';
import '../configs/configs.dart';
import '../theme/text_theme.dart';

class TimeNTP with ChangeNotifier {
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
              "Security alert!",
              style: CustomTextStyle.h4.copyWith(
                  color: ColorTheme.danger, fontWeight: FontWeight.w600),
            ),
            subTitle: Text(
              "You will be logged out of iTicket for security reasons as the device time has changed. Please log back in to continue.",
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

  Future<DateTime?> getTimeNTP() async => await FlutterKronos.getNtpDateTime;

  Future<dynamic> get() async {
    DateTime? now = await getTimeNTP();
    if (now == null) {
      return DateTime.now().toUtc();
    } else {
      print('[NTP] not null');
      return now.toUtc();
    }
  }

  Future<void> sync() async {
    FlutterKronos.sync();
    notifyListeners();
  }
}

final timeNTP = TimeNTP();

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class AlertHelper {
  void error(DioError err) {
    String message = err.response?.data?['message'] ?? err.message;
    print('[ERROR MESSAGE] $message');
    CherryToast.error(
      toastDuration: const Duration(seconds: 3),
      title: Text(
        message,
        style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
      ),
      toastPosition: Position.bottom,
      borderRadius: 5,
      displayCloseButton: false,
    ).show(NavigationService.navigatorKey.currentContext!);
  }
}

final alertHelper = AlertHelper();

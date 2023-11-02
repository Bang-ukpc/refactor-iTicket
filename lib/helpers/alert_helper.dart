import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class AlertHelper {
  void errorResponseApi(DioError err, {BuildContext? ctx}) {
    String message = "";
    if (err.response?.statusCode == 401) {
      message = err.response?.data?['message']['message'] ?? err.message;
    } else {
      message = err.response?.data?['message'] ?? err.message;
    }
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
    ).show(ctx ?? NavigationService.navigatorKey.currentContext!);
  }

  void error(String message, {BuildContext? ctx}) {
    CherryToast.error(
      displayCloseButton: false,
      title: Text(
        message,
        style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
      ),
      toastPosition: Position.bottom,
      borderRadius: 5,
    ).show(ctx ?? NavigationService.navigatorKey.currentContext!);
  }

  void success(String message, {BuildContext? ctx}) {
    CherryToast.success(
      displayCloseButton: false,
      title: Text(
        message,
        style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
      ),
      toastPosition: Position.bottom,
      borderRadius: 5,
    ).show(ctx ?? NavigationService.navigatorKey.currentContext!);
  }
}

final alertHelper = AlertHelper();

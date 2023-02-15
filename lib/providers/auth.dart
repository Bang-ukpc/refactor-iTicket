import 'dart:developer';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class Auth with ChangeNotifier {
  UserCachedService userCachedService = UserCachedService();

  Future<bool> isAuth() async {
    String? token = await SharedPreferencesHelper.getStringValue(
        PreferencesKeys.accessToken);
    return token != null ? true : false;
  }

  Future<void> loginWithMicrosoft(BuildContext context) async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);
    await oauth.login();
    final accessToken = await oauth.getIdToken();
    if (accessToken != null) {
      // ignore: use_build_context_synchronously
      showCircularProgressIndicator(context: context, text: 'Signing in');
      SharedPreferencesHelper.setStringValue(
          PreferencesKeys.accessToken, 'Bearer $accessToken');
      // ignore: use_build_context_synchronously
      await loginWithJwt(accessToken, context);
    }
  }

  Future<void> loginWithJwt(String jwt, BuildContext context) async {
    log('Logged in successfully, your access token: Bearer $jwt');
    try {
      await userController.getMe().then((value) async {
        await userCachedService.set(value);
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacementNamed(ConnectingScreen.routeName);
      });
    } on DioError catch (error) {
      if (error.type == DioErrorType.other) {
        Navigator.of(context).pop();
        CherryToast.error(
          toastDuration: const Duration(seconds: 3),
          title: Text(
            error.message.length > Constant.errorTypeOther
                ? 'Something went wrong, please try again'
                : error.message,
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        return;
      }
      Navigator.of(context).pop();
      await logout().then((value) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      });
    }
  }

  Future<void> logout() async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }

    await oauth.logout();

    SharedPreferencesHelper.removeStringValue(PreferencesKeys.accessToken);
    SharedPreferencesHelper.removeStringValue('rotaShiftSelectedByWarden');
    SharedPreferencesHelper.removeStringValue('locationSelectedByWarden');
    SharedPreferencesHelper.removeStringValue('zoneSelectedByWarden');
    userCachedService.remove;
    log('Logout successfully');
  }
}

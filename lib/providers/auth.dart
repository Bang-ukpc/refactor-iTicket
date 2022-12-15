import 'dart:developer';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:flutter/widgets.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  Future<bool> isAuth() async {
    String? token = await SharedPreferencesHelper.getStringValue(
        PreferencesKeys.accessToken);
    return token != null ? true : false;
  }

  Future<void> loginWithMicrosoft(
      BuildContext context, VoidCallback onLoading) async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);
    await oauth.login();
    final accessToken = await oauth.getIdToken();
    if (accessToken != null) {
      onLoading();
      SharedPreferencesHelper.setStringValue(
          PreferencesKeys.accessToken, 'Bearer $accessToken');
      // ignore: use_build_context_synchronously
      await loginWithJwt(accessToken, context);
    }
  }

  Future<void> loginWithJwt(String jwt, BuildContext context) async {
    log('Logged in successfully, your access token: Bearer $jwt');
    try {
      await userController.getMe().then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(ConnectingScreen.routeName);
      });
    } catch (error) {
      Navigator.of(context).pop();
      await logout().then((value) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'Login failed. Please try again',
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      });
    }
  }

  Future<void> logout() async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);
    await oauth.logout();

    final prefs = await SharedPreferences.getInstance();
    SharedPreferencesHelper.removeStringValue(PreferencesKeys.accessToken);
    prefs.clear();

    log('Logout successfully');
  }
}

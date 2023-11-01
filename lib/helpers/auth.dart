import 'dart:developer';

import 'package:aad_oauth/aad_oauth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/alert_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';
import 'package:iWarden/widgets/layouts/check_sync_data_layout.dart';

class Authentication {
  final UserCachedService userCachedService;

  Authentication(this.userCachedService);

  Future<bool> isAuth() async {
    String? token = await SharedPreferencesHelper.getStringValue(
        PreferencesKeys.accessToken);
    return token != null ? true : false;
  }

  Future<void> loginWithEmailOtp(String token, BuildContext ctx) async {
    showCircularProgressIndicator(context: ctx, text: 'Signing in');
    try {
      await userController.verifyToken(token).then((accessToken) async {
        SharedPreferencesHelper.setStringValue(
            PreferencesKeys.accessToken, accessToken);
        await loginWithJwt(accessToken, ctx);
      });
    } on DioError catch (e) {
      if (ctx.mounted) {
        Navigator.of(ctx).pop();
        alertHelper.error(e, ctx: ctx);
      }
    }
  }

  Future<void> loginWithMicrosoft(BuildContext ctx) async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);

    try {
      await oauth.login();
      final token = await oauth.getIdToken();

      if (token != null && ctx.mounted) {
        try {
          showCircularProgressIndicator(context: ctx, text: 'Signing in');
          await userController.verifyToken(token).then((accessToken) async {
            SharedPreferencesHelper.setStringValue(
                PreferencesKeys.accessToken, accessToken);
            await loginWithJwt(accessToken, ctx);
          });
        } on DioError catch (e) {
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            alertHelper.error(e, ctx: ctx);
            if (e.response?.statusCode == 401) {
              await logout();
            }
          }
        }
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> loginWithJwt(String jwt, BuildContext context) async {
    log('Logged in successfully, your access token: Bearer $jwt');
    try {
      await userController.getMe().then((value) async {
        await userCachedService.set(value);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context)
            .pushReplacementNamed(CheckSyncDataLayout.routeName);
      });
    } on DioError catch (error) {
      if (error.response?.statusCode == 401) {
        await logout().then((value) {
          alertHelper.error(error, ctx: context);
        });
        return;
      }
      if (!context.mounted) return;
      if (error.type == DioErrorType.other) {
        Navigator.of(context).pop();
        alertHelper.error(error, ctx: context);
        return;
      }
      Navigator.of(context).pop();
      await logout().then((value) {
        alertHelper.error(error, ctx: context);
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
    SharedPreferencesHelper.removeStringValue(
        PreferencesKeys.rotaShiftSelectedByWarden);
    SharedPreferencesHelper.removeStringValue(
        PreferencesKeys.locationSelectedByWarden);
    SharedPreferencesHelper.removeStringValue(
        PreferencesKeys.zoneSelectedByWarden);
    userCachedService.remove;
    log('Logout successfully');
  }
}

UserCachedService userCachedService = UserCachedService();
final authentication = Authentication(userCachedService);

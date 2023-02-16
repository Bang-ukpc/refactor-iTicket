import 'package:aad_oauth/aad_oauth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';

class Logging extends Interceptor {
  var userCachedService = UserCachedService();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    final accessToken = await SharedPreferencesHelper.getStringValue(
        PreferencesKeys.accessToken);
    options.headers['content-Type'] = 'application/json';
    options.headers["authorization"] = accessToken;
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    final AadOAuth oauth = AadOAuth(OAuthConfig.config);
    print(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    if (err.response?.statusCode == 401) {
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
      userCachedService.remove();
      NavigationService.navigatorKey.currentState!.pushNamedAndRemoveUntil(
          LoginScreen.routeName, (Route<dynamic> route) => false);
    }

    return super.onError(err, handler);
  }
}

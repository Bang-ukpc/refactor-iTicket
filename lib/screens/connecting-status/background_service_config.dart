import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final accessToken = await SharedPreferencesHelper.getStringValue(
    PreferencesKeys.accessToken,
  );
  const serviceURL = "http://192.168.1.200:7003";
  final dio = Dio();
  dio.options.headers['content-Type'] = 'application/json';
  dio.options.headers["authorization"] = accessToken;
  final response = await dio.get('$serviceURL/warden/get-me');
  final wardenFromJson = Wardens.fromJson(response.data);
  Position position = await Geolocator.getCurrentPosition();

  final wardenEventSendCurrentLocation = WardenEvent(
    type: TypeWardenEvent.TrackGPS.index,
    detail: "Warden's current location",
    latitude: position.latitude,
    longitude: position.longitude,
    wardenId: wardenFromJson.Id ?? 0,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'iTicket Service',
          'iTicket Service',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }

    try {
      await dio.post(
        '$serviceURL/wardenEvent',
        data: wardenEventSendCurrentLocation.toJson(),
      );
    } on DioError catch (err) {
      if (err.response!.statusCode == 401) {
        service.stopSelf();
      }
    }
  });
}

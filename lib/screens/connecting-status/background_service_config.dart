import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/models/zone.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      initialNotificationTitle: 'iTicket Service',
      initialNotificationContent: 'iTicket Service',
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
  // const serviceUrl = 'https://api-warden-admin-dev-ukpc.azurewebsites.net';
  const serviceUrl = 'http://192.168.1.200:7004';
  final dio = Dio();
  dio.options.headers['content-Type'] = 'application/json';
  dio.options.headers["authorization"] = accessToken;
  Position position = await Geolocator.getCurrentPosition();

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
      final prefs = await SharedPreferences.getInstance();
      prefs.reload();
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

    Wardens? wardenFromJson;
    final String? warden =
        await SharedPreferencesHelper.getStringValue('wardenDataLocal');
    if (warden != null) {
      final decodedWarden = json.decode(warden) as Map<String, dynamic>;
      wardenFromJson = Wardens.fromJson(decodedWarden);
    }

    final String? rotaShift = await SharedPreferencesHelper.getStringValue(
        'rotaShiftSelectedByWarden');
    final String? locations = await SharedPreferencesHelper.getStringValue(
        'locationSelectedByWarden');
    final String? zone =
        await SharedPreferencesHelper.getStringValue('zoneSelectedByWarden');
    RotaWithLocation? rotaShiftSelected;
    LocationWithZones? locationSelected;
    Zone? zoneSelected;

    if (rotaShift != null) {
      rotaShiftSelected = RotaWithLocation.fromJson(json.decode(rotaShift));
    }

    if (locations != null) {
      locationSelected = LocationWithZones.fromJson(json.decode(locations));
    }

    if (zone != null) {
      zoneSelected = Zone.fromJson(json.decode(zone));
    }

    final wardenEventSendCurrentLocation = WardenEvent(
      type: TypeWardenEvent.TrackGPS.index,
      detail: "Warden's current location",
      latitude: position.latitude,
      longitude: position.longitude,
      wardenId: wardenFromJson?.Id ?? 0,
      rotaTimeFrom: rotaShiftSelected?.timeFrom,
      rotaTimeTo: rotaShiftSelected?.timeTo,
      locationId: locationSelected?.Id,
      zoneId: zoneSelected?.Id,
    );

    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        await dio.post(
          '$serviceUrl/wardenEvent',
          data: wardenEventSendCurrentLocation.toJson(),
        );
      } on DioError catch (err) {
        if (err.type != DioErrorType.other) {
          service.stopSelf();
        }
      }
    } else {
      wardenEventSendCurrentLocation.Created = DateTime.now();
      final String? wardenEventDataLocal =
          await SharedPreferencesHelper.getStringValue(
              'wardenEventCheckGPSDataLocal');
      final String encodedNewData =
          json.encode(wardenEventSendCurrentLocation.toJson());

      if (wardenEventDataLocal == null) {
        List<String> newData = [];
        newData.add(encodedNewData);
        final encodedWardenEvent = json.encode(newData);
        SharedPreferencesHelper.setStringValue(
            'wardenEventCheckGPSDataLocal', encodedWardenEvent);
      } else {
        var createdData = json.decode(wardenEventDataLocal) as List<dynamic>;
        createdData.add(encodedNewData);
        final encodedCreatedData = json.encode(createdData);
        SharedPreferencesHelper.setStringValue(
            'wardenEventCheckGPSDataLocal', encodedCreatedData);
      }
    }
  });
}

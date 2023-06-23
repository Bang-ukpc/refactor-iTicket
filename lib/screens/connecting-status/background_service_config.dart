import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/id_helper.dart';
import 'package:iWarden/helpers/ntp_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/models/zone.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/local/sync_factory.dart';

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
  await dotenv.load(fileName: ".env");
  DartPluginRegistrant.ensureInitialized();
  final accessToken = await SharedPreferencesHelper.getStringValue(
    PreferencesKeys.accessToken,
  );

  final dio = Dio();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  dio.options.headers["x-application-version"] = version;
  dio.options.headers['content-Type'] = 'application/json';
  dio.options.headers["authorization"] = accessToken;

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

  service.on('startShiftService').listen((event) async {
    await SharedPreferencesHelper.setBoolValue('isEndShift', false);
  });

  service.on('endShiftService').listen((event) async {
    await SharedPreferencesHelper.setBoolValue('isEndShift', true);
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    syncFactory.syncToServer();
    await currentLocationPosition.getCurrentLocation();
  });

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.reload();
    bool isEndShift =
        await SharedPreferencesHelper.getBoolValue('isEndShift') ?? false;
    if (!isEndShift) {
      DateTime ntp = await ntpHelper.getTimeNTP();
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

      var userCachedService = UserCachedService();
      final Wardens? warden = await userCachedService.get();
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

      final gpsEvent = WardenEvent(
        Id: idHelper.generateId(),
        type: TypeWardenEvent.TrackGPS.index,
        detail: "Warden's current location",
        latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        wardenId: warden?.Id ?? 0,
        rotaTimeFrom: rotaShiftSelected?.timeFrom,
        rotaTimeTo: rotaShiftSelected?.timeTo,
        locationId: locationSelected?.Id,
        zoneId: zoneSelected?.Id,
        Created: ntp,
      );

      createdWardenEventLocalService.create(gpsEvent);
    }
  });
}

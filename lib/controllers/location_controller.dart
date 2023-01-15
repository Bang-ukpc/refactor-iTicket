import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/location.dart';

class LocationController {
  static final dio = DioHelper.defaultApiClient;
  Future<List<LocationWithZones>> getAll(
    ListLocationOfTheDayByWardenIdProps listLocationOfTheDayByWardenIdProps,
  ) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      log('connected network');
      try {
        final response = await dio.post(
          '/location/location-of-the-day-by-warden',
          data: listLocationOfTheDayByWardenIdProps.toJson(),
        );
        List<dynamic> temp = response.data;
        print(temp);
        List<LocationWithZones> locations =
            temp.map((model) => LocationWithZones.fromJson(model)).toList();
        final String encodedData = LocationWithZones.encode(locations);
        SharedPreferencesHelper.setStringValue(
            'locationDataLocal', encodedData);
        return locations;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      log('not connect network');
      final String? data =
          await SharedPreferencesHelper.getStringValue('locationDataLocal');
      if (data != null) {
        final List<LocationWithZones> locations =
            LocationWithZones.decode(data);
        return locations;
      }
      return [];
    }
  }
}

final locationController = LocationController();

import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/location.dart';

class LocationController {
  static final dio = DioHelper.defaultApiClient;
  Future<List<RotaWithLocation>> getAll(
    ListLocationOfTheDayByWardenIdProps listLocationOfTheDayByWardenIdProps,
  ) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.post(
          '/location/location-of-the-day-by-warden',
          data: listLocationOfTheDayByWardenIdProps.toJson(),
        );
        List<dynamic> temp = response.data;
        log(temp.toString());
        log('123');
        List<RotaWithLocation> rotaWithLocations =
            temp.map((model) => RotaWithLocation.fromJson(model)).toList();
        log('456');
        final String encodedData = RotaWithLocation.encode(rotaWithLocations);
        SharedPreferencesHelper.setStringValue(
            'rotaWithLocationDataLocal', encodedData);
        return rotaWithLocations;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data = await SharedPreferencesHelper.getStringValue(
          'rotaWithLocationDataLocal');
      if (data != null) {
        final List<RotaWithLocation> locations = RotaWithLocation.decode(data);
        return locations;
      }
      return [];
    }
  }
}

final locationController = LocationController();

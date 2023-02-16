import 'dart:async';

import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/location.dart';

class LocationController {
  late Dio dio;

  LocationController() {
    dio = DioHelper.defaultApiClient;
  }

  LocationController.fromDio(Dio initDio) {
    dio = initDio;
  }

  Future<List<RotaWithLocation>> getAll(
    ListLocationOfTheDayByWardenIdProps listLocationOfTheDayByWardenIdProps,
  ) async {
    try {
      final response = await dio.post(
        '/location/location-of-the-day-by-warden',
        data: listLocationOfTheDayByWardenIdProps.toJson(),
      );
      List<dynamic> temp = response.data;
      List<RotaWithLocation> rotaWithLocations =
          temp.map((model) => RotaWithLocation.fromJson(model)).toList();
      return rotaWithLocations;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final locationController = LocationController();

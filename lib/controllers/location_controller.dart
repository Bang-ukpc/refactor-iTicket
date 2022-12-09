import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/location.dart';

class LocationController {
  static final dio = DioHelper.defaultApiClient;
  Future<List<LocationWithZones>> getAll(
      ListLocationOfTheDayByWardenIdProps
          listLocationOfTheDayByWardenIdProps) async {
    try {
      final response = await dio.post(
        '/location/location-of-the-day-by-warden',
        data: listLocationOfTheDayByWardenIdProps.toJson(),
      );
      List<dynamic> temp = response.data;
      List<LocationWithZones> locations =
          temp.map((model) => LocationWithZones.fromJson(model)).toList();
      return locations;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final locationController = LocationController();

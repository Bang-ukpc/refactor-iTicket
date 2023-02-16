import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/statistic.dart';

class StatisticController {
  late Dio dio;

  StatisticController() {
    dio = DioHelper.defaultApiClient;
  }

  StatisticController.fromDio(Dio initDio) {
    dio = initDio;
  }

  Future<StatisticWardenPropsData> getDataStatistic(
      StatisticWardenPropsFilter filter) async {
    final bodyRequest = jsonEncode({
      "ZoneId": filter.zoneId,
      "timeStart": filter.timeStart.toString(),
      "timeEnd": filter.timeEnd.toString(),
      'WardenId': filter.WardenId,
    });
    try {
      final response =
          await dio.post('/vehicleInformation/statistics', data: bodyRequest);
      StatisticWardenPropsData statisticData =
          StatisticWardenPropsData.fromJson(response.data);
      final String encodedData = json.encode(statisticData.toJson());
      SharedPreferencesHelper.setStringValue(
          'StatisticWardenPropsDataLocal', encodedData);
      return statisticData;
    } on DioError catch (error) {
      print(error.response);
      return StatisticWardenPropsData(
        abortedPCN: 0,
        firstSeen: 0,
        gracePeriod: 0,
        issuedPCN: 0,
      );
    }
  }
}

final statisticController = StatisticController();

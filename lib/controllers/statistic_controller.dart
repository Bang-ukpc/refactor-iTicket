import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/statistic.dart';

class StatisticController {
  static final dio = DioHelper.defaultApiClient;
  Future<StatisticWardenPropsData> getDataStatistic(
      StatisticWardenPropsFilter filter) async {
    final bodyRequest = jsonEncode({
      "ZoneId": filter.zoneId,
      "timeStart": filter.timeStart.toString(),
      "timeEnd": filter.timeEnd.toString(),
    });
    try {
      final response = await DioHelper.defaultApiClient
          .post('/vehicleInformation/statistics', data: bodyRequest);
      StatisticWardenPropsData statisticData =
          StatisticWardenPropsData.fromJson(response.data);
      return statisticData;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final statisticController = StatisticController();

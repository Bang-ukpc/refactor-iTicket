import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/statistic.dart';

class StatisticController {
  static final dio = DioHelper.defaultApiClient;
  Future<StatisticWardenPropsData> getDataStatistic(
      StatisticWardenPropsFilter filter) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
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
        final String encodedData =
            json.encode(StatisticWardenPropsData.toJson(statisticData));
        SharedPreferencesHelper.setStringValue(
            'StatisticWardenPropsDataLocal', encodedData);
        return statisticData;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data = await SharedPreferencesHelper.getStringValue(
          'StatisticWardenPropsDataLocal');
      if (data != null) {
        final statisticData = json.decode(data) as Map<String, dynamic>;
        return StatisticWardenPropsData.fromJson(statisticData);
      }
      return StatisticWardenPropsData(
          abortedPCN: 0, firstSeen: 0, gracePeriod: 0, issuedPCN: 0);
    }
  }
}

final statisticController = StatisticController();

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';

class VehicleInfoController {
  static final dio = DioHelper.defaultApiClient;
  Future<Pagination> getVehicleInfoList(
      {required int vehicleInfoType,
      required int zoneId,
      int? page,
      int? pageSize}) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      final bodyRequest = jsonEncode({
        "filter": {
          "type": vehicleInfoType,
          "CarLeft": false,
          "zoneId": zoneId,
        },
        "page": page,
        "pageSize": pageSize,
        "sorts": ["-ExpiredAt"],
      });
      try {
        final response =
            await dio.post('/vehicleInformation/filter', data: bodyRequest);
        Pagination vehicleInfoPagination = Pagination.fromJson(response.data);
        final String encodedData =
            json.encode(Pagination.toJson(vehicleInfoPagination));
        SharedPreferencesHelper.setStringValue(
            'vehicleInfoDataLocal', encodedData);
        return vehicleInfoPagination;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data =
          await SharedPreferencesHelper.getStringValue('vehicleInfoDataLocal');
      final vehicleInfo = json.decode(data as String) as Map<String, dynamic>;
      return Pagination.fromJson(vehicleInfo);
    }
  }

  Future<VehicleInformation> upsertVehicleInfo(
      VehicleInformation vehicleInfo) async {
    try {
      final response = await dio.post(
        '/vehicleInformation',
        data: vehicleInfo.toJson(),
      );
      final vehicleFromJson = VehicleInformation.fromJson(response.data);
      return vehicleFromJson;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<VehicleInformation> getVehicleInfoDetail(int vehicleId) async {
    try {
      final response = await dio.get(
        vehicleId.toString(),
      );
      final vehicleFromJson = VehicleInformation.fromJson(response.data);
      return vehicleFromJson;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final vehicleInfoController = VehicleInfoController();

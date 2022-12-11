import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';

class VehicleInfoController {
  static final dio = DioHelper.defaultApiClient;
  Future<Pagination> getVehicleInfoList(
      {required int vehicleInfoType,
      required int zoneId,
      int? page,
      int? pageSize}) async {
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
      return vehicleInfoPagination;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
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

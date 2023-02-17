import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';

class VehicleInfoController {
  late Dio dio;

  VehicleInfoController() {
    dio = DioHelper.defaultApiClient;
  }

  VehicleInfoController.fromDio(Dio initDio) {
    dio = initDio;
  }

  Future<Pagination> getVehicleInfoList(
      {required int vehicleInfoType,
      required int zoneId,
      required int page,
      required pageSize}) async {
    print('[API] with zoneId: $zoneId');
    final bodyRequest = jsonEncode({
      "filter": {
        "type": vehicleInfoType,
        "CarLeftAt": null,
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
      var vehicleInfos = jsonDecodeFactory
          .decodeList<VehicleInformation>(vehicleInfoPagination.rows);
      vehicleInfoPagination.rows = vehicleInfos;

      return vehicleInfoPagination;
    } on DioError catch (error) {
      print('[API GET VEHICLE INFO] $error');
      rethrow;
    }
  }

  Future<VehicleInformation?> upsertVehicleInfo(
      VehicleInformation vehicleInfo) async {
    try {
      final response = await dio.post(
        '/vehicleInformation',
        data: vehicleInfo.toJson(),
      );
      print('[RESPONSE DATA VEHICLE INFO] ${response.data}');
      if (response.data != null) {
        final vehicleFromJson = VehicleInformation.fromJson(response.data);
        return vehicleFromJson;
      }
      return null;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final vehicleInfoController = VehicleInfoController();

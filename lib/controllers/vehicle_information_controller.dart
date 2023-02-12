import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
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
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      print('[API] with zoneId: ${zoneId}');
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
        var vehicleInfos = jsonDecodeFactory
            .decodeList<VehicleInformation>(vehicleInfoPagination.rows);
        vehicleInfoPagination.rows = vehicleInfos;
        Pagination vehicleInfoDataLocal = Pagination.fromJson(response.data);
        print("[DETAIL] ${json.encode(vehicleInfoDataLocal.toJson())}");
        final String? data = await SharedPreferencesHelper.getStringValue(
            'vehicleInfoDataLocal');
        if (data == null) {
          final String encodedData = json.encode(vehicleInfoDataLocal.toJson());
          SharedPreferencesHelper.setStringValue(
            'vehicleInfoDataLocal',
            encodedData,
          );
        } else {
          final vehicleInfo = json.decode(data) as Map<String, dynamic>;
          Pagination fromJsonVehicleInfo = Pagination.fromJson(vehicleInfo);
          if (vehicleInfoType == VehicleInformationType.FIRST_SEEN.index) {
            fromJsonVehicleInfo.rows.removeWhere((i) {
              if (i['Type'] == VehicleInformationType.FIRST_SEEN.index) {
                return i['Type'] == VehicleInformationType.FIRST_SEEN.index;
              }
              return false;
            });
          } else {
            fromJsonVehicleInfo.rows.removeWhere((i) {
              if (i['Type'] == VehicleInformationType.GRACE_PERIOD.index) {
                return i['Type'] == VehicleInformationType.GRACE_PERIOD.index;
              }
              return false;
            });
          }
          vehicleInfoDataLocal.rows = List.from(vehicleInfoDataLocal.rows)
            ..addAll(fromJsonVehicleInfo.rows);
          final String encodedData = json.encode(vehicleInfoDataLocal.toJson());
          SharedPreferencesHelper.setStringValue(
            'vehicleInfoDataLocal',
            encodedData,
          );
        }

        return vehicleInfoPagination;
      } on DioError catch (error) {
        print('[API GET VEHICLE INFO] ${error}');
        rethrow;
      }
    } else {
      final String? data =
          await SharedPreferencesHelper.getStringValue('vehicleInfoDataLocal');
      final String? dataUpsert = await SharedPreferencesHelper.getStringValue(
          'vehicleInfoUpsertDataLocal');
      if (data != null) {
        final vehicleInfo = json.decode(data) as Map<String, dynamic>;
        Pagination fromJsonVehicleInfo = Pagination.fromJson(vehicleInfo);
        if (dataUpsert != null) {
          final vehicleInfoUpsertData =
              json.decode(dataUpsert) as List<dynamic>;
          fromJsonVehicleInfo.rows = List.from(fromJsonVehicleInfo.rows)
            ..addAll(vehicleInfoUpsertData.map((v) => json.decode(v)));
        }
        fromJsonVehicleInfo.rows = fromJsonVehicleInfo.rows
            .where((i) =>
                i['ZoneId'] == zoneId &&
                i['Type'] == vehicleInfoType &&
                i['CarLeft'] == false)
            .toList();
        return fromJsonVehicleInfo;
      } else {
        if (dataUpsert != null) {
          var vehicleInfoUpsertData = json.decode(dataUpsert) as List<dynamic>;
          vehicleInfoUpsertData =
              vehicleInfoUpsertData.map((v) => json.decode(v)).toList();
          vehicleInfoUpsertData = vehicleInfoUpsertData
              .where((f) =>
                  f['ZoneId'] == zoneId &&
                  f['Type'] == vehicleInfoType &&
                  f['CarLeft'] == false)
              .toList();
          return Pagination(
            page: page,
            pageSize: pageSize,
            total: vehicleInfoUpsertData.length,
            totalPages: 1,
            rows: vehicleInfoUpsertData,
          );
        }
      }
      return Pagination(
          page: page, pageSize: pageSize, total: 0, totalPages: 1, rows: []);
    }
  }

  Future<VehicleInformation?> upsertVehicleInfo(
      VehicleInformation vehicleInfo) async {
    try {
      final response = await dio.post(
        '/vehicleInformation',
        data: vehicleInfo.toJson(),
      );
      print(response.data);
      if (response.data != null) {
        final vehicleFromJson = VehicleInformation.fromJson(response.data);
        return vehicleFromJson;
      }
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final vehicleInfoController = VehicleInfoController();

import 'dart:convert';
import 'dart:developer';

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
      required int page,
      required pageSize}) async {
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
        Pagination vehicleInfoDataLocal = Pagination.fromJson(response.data);

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
        print(error.response);
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
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.post(
          '/vehicleInformation',
          data: vehicleInfo.toJson(),
        );
        print(response.data);
        final vehicleFromJson = VehicleInformation.fromJson(response.data);
        return vehicleFromJson;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? dataList =
          await SharedPreferencesHelper.getStringValue('vehicleInfoDataLocal');
      final String? vehicleUpsertData =
          await SharedPreferencesHelper.getStringValue(
              'vehicleInfoUpsertDataLocal');

      if (vehicleUpsertData != null) {
        var decodedData = json.decode(vehicleUpsertData) as List<dynamic>;
        decodedData = decodedData.map(((i) => json.decode(i))).toList();
        var index = decodedData.indexWhere((r) => r['Id'] == vehicleInfo.Id);
        if (index != -1) {
          decodedData[index]['CarLeft'] = true;
        } else {
          decodedData.add(vehicleInfo.toJson());
          if (dataList != null) {
            final vehicleInfoDataLocal =
                json.decode(dataList) as Map<String, dynamic>;
            Pagination fromJsonVehicleInfo =
                Pagination.fromJson(vehicleInfoDataLocal);
            var position = fromJsonVehicleInfo.rows
                .indexWhere((i) => i['Id'] == vehicleInfo.Id);
            if (position != -1) {
              fromJsonVehicleInfo.rows.removeAt(position);
            }
            final String encodedDataList =
                json.encode(fromJsonVehicleInfo.toJson());
            SharedPreferencesHelper.setStringValue(
                'vehicleInfoDataLocal', encodedDataList);
          }
        }
        decodedData = decodedData.map(((i) => json.encode(i))).toList();
        final String encodedData = json.encode(decodedData);
        SharedPreferencesHelper.setStringValue(
            'vehicleInfoUpsertDataLocal', encodedData);
      } else {
        final String encodedNewData = json.encode(vehicleInfo.toJson());
        List<String> newData = [];
        newData.add(encodedNewData);
        if (dataList != null) {
          final vehicleInfoDataLocal =
              json.decode(dataList) as Map<String, dynamic>;
          Pagination fromJsonVehicleInfo =
              Pagination.fromJson(vehicleInfoDataLocal);
          var position = fromJsonVehicleInfo.rows
              .indexWhere((i) => i['Id'] == vehicleInfo.Id);
          if (position != -1) {
            fromJsonVehicleInfo.rows.removeAt(position);
          }
          final String encodedDataList =
              json.encode(fromJsonVehicleInfo.toJson());
          SharedPreferencesHelper.setStringValue(
              'vehicleInfoDataLocal', encodedDataList);
        }
        final newVehicle = json.encode(newData);
        SharedPreferencesHelper.setStringValue(
            'vehicleInfoUpsertDataLocal', newVehicle);
      }
      return vehicleInfo;
    }
  }
}

final vehicleInfoController = VehicleInfoController();

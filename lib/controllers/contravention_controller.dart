import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_registration.dart';

class ContraventionController {
  static final dio = DioHelper.defaultApiClient;
  Future<Contravention> createPCN(ContraventionCreateWardenCommand pcn) async {
    try {
      final response = await dio.post(
        '/contravention/create-pcn',
        data: ContraventionCreateWardenCommand.toJson(pcn),
      );
      print(response.data.toString());
      Contravention contraventionResult = Contravention.fromJson(response.data);
      print('Api create PCN: ${response.data}');
      return contraventionResult;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<Contravention?> getContraventionDetail(int id) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.get(
          '/contravention/$id',
        );
        Contravention contraventionResult =
            Contravention.fromJson(response.data);
        return contraventionResult;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data = await SharedPreferencesHelper.getStringValue(
          'contraventionDataLocal');
      if (data != null) {
        final contraventions = json.decode(data) as Map<String, dynamic>;
        Pagination fromJsonContravention = Pagination.fromJson(contraventions);
        List<Contravention> contraventionList = fromJsonContravention.rows
            .map((item) => Contravention.fromJson(item))
            .toList();
        var index = contraventionList.indexWhere((i) => i.id == id);
        return contraventionList[index];
      }
      return null;
    }
  }

  Future<Pagination> getContraventionServiceList(
      {required int zoneId, required int page, required int pageSize}) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.post(
          '/contravention/filter',
          data: {
            "page": page,
            "pageSize": pageSize,
            "sorts": ["-Created"],
            "filter": {
              "zoneId": zoneId,
            }
          },
        );
        Pagination contraventionPagination = Pagination.fromJson(response.data);
        final String encodedData =
            json.encode(Pagination.toJson(contraventionPagination));
        SharedPreferencesHelper.setStringValue(
            'contraventionDataLocal', encodedData);
        return contraventionPagination;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data = await SharedPreferencesHelper.getStringValue(
          'contraventionDataLocal');
      if (data != null) {
        final contraventions = json.decode(data) as Map<String, dynamic>;
        Pagination fromJsonContravention = Pagination.fromJson(contraventions);
        fromJsonContravention.rows = fromJsonContravention.rows
            .where((i) =>
                i['ZoneId'] == zoneId &&
                i['Status'] == ContraventionStatus.Open.index)
            .toList();
        fromJsonContravention.rows
            .sort((i1, i2) => i2['Created'].compareTo(i1['Created']));
        return fromJsonContravention;
      } else {
        return Pagination(
            page: page, pageSize: pageSize, total: 0, totalPages: 1, rows: []);
      }
    }
  }

  Future<Pagination> getContraventionReasonServiceList({int? zoneId}) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.post(
          '/contravention-reason-translation/filter',
          data: {
            "page": 1,
            "pageSize": 1000,
            "ZoneId": zoneId,
            "filter": {},
          },
        );
        print(response.data);
        Pagination contraventionReasonPagination =
            Pagination.fromJson(response.data);
        final String encodedData =
            json.encode(Pagination.toJson(contraventionReasonPagination));
        if (zoneId != null) {
          SharedPreferencesHelper.setStringValue(
              'contraventionReasonDataLocalWithHaveZoneId', encodedData);
        } else {
          SharedPreferencesHelper.setStringValue(
              'contraventionReasonDataLocalWithNotHaveZoneId', encodedData);
        }
        return contraventionReasonPagination;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? dataHaveZoneId =
          await SharedPreferencesHelper.getStringValue(
              'contraventionReasonDataLocalWithHaveZoneId');
      final String? dataNotHaveZoneId =
          await SharedPreferencesHelper.getStringValue(
              'contraventionReasonDataLocalWithNotHaveZoneId');

      if (zoneId != null) {
        if (dataHaveZoneId != null) {
          final contraventionReason =
              json.decode(dataHaveZoneId) as Map<String, dynamic>;
          Pagination fromJsonContraventionReason =
              Pagination.fromJson(contraventionReason);
          return fromJsonContraventionReason;
        }
      } else {
        if (dataNotHaveZoneId != null) {
          final contraventionReason =
              json.decode(dataNotHaveZoneId) as Map<String, dynamic>;
          Pagination fromJsonContraventionReason =
              Pagination.fromJson(contraventionReason);
          return fromJsonContraventionReason;
        }
      }

      return Pagination(
        page: 1,
        pageSize: 1000,
        total: 0,
        totalPages: 1,
        rows: [],
      );
    }
  }

  Future<VehicleRegistration?> getVehicleDetailByPlate(
      {required String plate}) async {
    try {
      final response = await dio.get(
        '/contravention/vehicle-details/$plate',
      );
      print(response.data);
      VehicleRegistration vehicleRegistration =
          VehicleRegistration.fromJson(response.data);
      return vehicleRegistration;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<CheckPermit?> checkHasPermit(
      ContraventionCreateWardenCommand pcn) async {
    print('data: ${pcn.Plate}');
    print('data: ${pcn.WardenComments}');
    try {
      final response = await dio.post(
        '/contravention/check-has-permit',
        data: ContraventionCreateWardenCommand.toJson(pcn),
      );
      print('check permit: ${response.data}');
      CheckPermit data = CheckPermit.fromJson(response.data);
      return data;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<dynamic> uploadContraventionImage(
      ContraventionCreatePhoto contraventionCreatePhoto) async {
    var formData = FormData.fromMap({
      'contraventionReference': contraventionCreatePhoto.contraventionReference,
      'photoType': contraventionCreatePhoto.photoType.toString(),
      'originalFileName': contraventionCreatePhoto.originalFileName,
      'capturedDateTime':
          contraventionCreatePhoto.capturedDateTime.toIso8601String(),
      'file': await MultipartFile.fromFile(
        contraventionCreatePhoto.filePath,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    var response =
        await dio.post('/contravention/create-photo-pcn', data: formData);
    return response.data;
  }
}

final contraventionController = ContraventionController();

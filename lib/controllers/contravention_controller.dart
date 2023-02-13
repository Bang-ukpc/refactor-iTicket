import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_registration.dart';

class ContraventionController {
  late Dio dio;

  ContraventionController() {
    dio = DioHelper.defaultApiClient;
  }

  ContraventionController.fromDio(Dio initDio) {
    dio = initDio;
  }

  Future<Contravention> createPCN(ContraventionCreateWardenCommand pcn) async {
    try {
      final response = await dio.post(
        '/contravention/create-pcn',
        data: pcn.toJson(),
      );
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

      print('[Contravention paging] ${contraventionPagination.rows.length}');

      contraventionPagination.rows = jsonDecodeFactory
          .decodeList<Contravention>(contraventionPagination.rows);
      print('[Contravention result] ${contraventionPagination.rows}');
      return contraventionPagination;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<Pagination> getContraventionReasonServiceList({int? zoneId}) async {
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
      print('[CONTRAVENTION REASON] ${response.data}');
      Pagination contraventionReasonPagination =
          Pagination.fromJson(response.data);
      contraventionReasonPagination.rows =
          jsonDecodeFactory.decodeList<ContraventionReasonTranslations>(
              contraventionReasonPagination.rows);
      return contraventionReasonPagination;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
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
    try {
      final response = await dio.post(
        '/contravention/check-has-permit',
        data: pcn.toJson(),
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

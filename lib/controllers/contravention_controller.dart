import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
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
        '/contravention/create-pcn-v2',
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

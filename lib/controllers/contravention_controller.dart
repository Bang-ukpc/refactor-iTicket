import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/helpers/dio_helper.dart';
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
        data: pcn.toJson(),
      );
      Contravention contraventionResult = Contravention.fromJson(response.data);
      print('Api create PCN: ${response.data}');
      return contraventionResult;
    } catch (error) {
      rethrow;
    }
  }

  Future<Contravention> getContraventionDetail(int id) async {
    try {
      final response = await dio.get(
        '/contravention/$id',
      );
      Contravention contraventionResult = Contravention.fromJson(response.data);
      return contraventionResult;
    } catch (error) {
      rethrow;
    }
  }

  Future<Pagination> getContraventionServiceList(
      {required int zoneId, int? page, int? pageSize}) async {
    print('zoneId: $zoneId');
    try {
      final response = await dio.post(
        '/contravention/filter',
        data: {
          "page": page,
          "pageSize": pageSize,
          "sorts": ["-Created"],
          "filter": {
            "status": ContraventionStatus.Open.index,
            "zoneId": zoneId,
          }
        },
      );
      Pagination contraventionPagination = Pagination.fromJson(response.data);
      return contraventionPagination;
    } catch (error) {
      rethrow;
    }
  }

  Future<Pagination> getContraventionReasonServiceList() async {
    try {
      final response = await dio.post(
        '/contravention-reason-translation/filter',
        data: {
          "page": 1,
          "pageSize": 1000,
        },
      );
      Pagination contraventionReasonPagination =
          Pagination.fromJson(response.data);
      return contraventionReasonPagination;
    } catch (error) {
      rethrow;
    }
  }

  Future<VehicleRegistration?> getVehicleDetailByPlate(
      {required String plate}) async {
    try {
      final response = await dio.get(
        '/contravention/vehicle-details/$plate',
      );
      if (response.data != '') {
        VehicleRegistration vehicleRegistration =
            VehicleRegistration.fromJson(response.data);
        return vehicleRegistration;
      } else {
        return null;
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<dynamic> uploadContraventionImage(
      ContraventionCreatePhoto contraventionCreatePhoto) async {
    String fileName = contraventionCreatePhoto.file!.path;
    var formData = FormData.fromMap({
      'contraventionReference': contraventionCreatePhoto.contraventionReference,
      'photoType': contraventionCreatePhoto.photoType.toString(),
      'originalFileName': contraventionCreatePhoto.originalFileName,
      'capturedDateTime':
          contraventionCreatePhoto.capturedDateTime.toIso8601String(),
      'file': await MultipartFile.fromFile(
        fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    var response =
        await dio.post('/contravention/create-photo-pcn', data: formData);
    return response.data;
  }
}

final contraventionController = ContraventionController();

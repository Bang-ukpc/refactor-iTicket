import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/helpers/dio_helper.dart';

class EvidencePhotoController {
  static final dio = DioHelper.defaultApiClient;
  Future<dynamic> uploadImage(File image) async {
    String fileName = image.path;
    var formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    var response = await dio.post('/evidencePhoto/upload', data: formData);
    return response.data;
  }
}

final evidencePhotoController = EvidencePhotoController();

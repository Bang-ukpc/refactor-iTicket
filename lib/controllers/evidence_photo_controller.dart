import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:iWarden/helpers/dio_helper.dart';

class EvidencePhotoController {
  static final dio = DioHelper.defaultApiClient;
  Future<dynamic> uploadImage(
      {required String filePath, DateTime? capturedDateTime}) async {
    var formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        filePath,
        contentType: MediaType('image', 'jpeg'),
      ),
      'CapturedDateTime': capturedDateTime,
    });
    var response = await dio.post('/evidencePhoto/upload', data: formData);
    return response.data;
  }
}

final evidencePhotoController = EvidencePhotoController();

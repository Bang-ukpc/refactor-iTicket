import 'package:dio/dio.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/contravention.dart';

class ContraventionReasonController {
  static final dio = DioHelper.defaultApiClient;

  Future<List<ContraventionReasonTranslations>> all() async {
    try {
      final response = await dio.get('/contravention/list-cancellation-reason');
      return jsonDecodeFactory.decodeList<ContraventionReasonTranslations>(
          (response.data as dynamic).rows);
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final contraventionReasonController = ContraventionReasonController();

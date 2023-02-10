import 'package:dio/dio.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/abort_pcn.dart';

class CancellationReasonController {
  static final dio = DioHelper.defaultApiClient;

  Future<List<CancellationReason>> all() async {
    try {
      final response = await dio.get('/contravention/list-cancellation-reason');
      return jsonDecodeFactory.decodeList<CancellationReason>(response.data);
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final cancellationReasonController = CancellationReasonController();

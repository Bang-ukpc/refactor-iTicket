import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/abort_pcn.dart';

class AbortController {
  static final dio = DioHelper.defaultApiClient;

  Future<List<CancellationReason>> getCancellationReasonList() async {
    try {
      final response = await dio.get(
        '/contravention/list-cancellation-reason',
      );
      List<dynamic> temp = response.data;
      List<CancellationReason> cancellationReasons =
          temp.map((model) => CancellationReason.fromJson(model)).toList();
      return cancellationReasons;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<void> abortPCN(AbortPCN abortPcn) async {
    try {
      final response = await dio.post(
        '/contravention/abort-pcn',
        data: abortPcn.toJson(),
      );
      return response.data;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final abortController = AbortController();

import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/wardens.dart';

class UserController {
  late Dio dio;

  UserController() {
    dio = DioHelper.defaultApiClient;
  }

  UserController.fromDio(Dio initDio) {
    dio = initDio;
  }

  Future<Wardens> getMe() async {
    try {
      final response = await dio.get('/warden/get-me');
      return Wardens.fromJson(response.data);
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<WardenEvent> createWardenEvent(WardenEvent wardenEvent) async {
    try {
      final response =
          await dio.post('/wardenEvent', data: wardenEvent.toJson());
      final wardenEventFromJson = WardenEvent.fromJson(response.data);
      return wardenEventFromJson;
    } on DioError catch (error) {
      print('[WARDEN EVENT] ${error.response}');
      rethrow;
    }
  }
}

final userController = UserController();

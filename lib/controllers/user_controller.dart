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
      final response = await dio.get('/account/warden/get-me');
      return Wardens.fromJson(response.data);
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<void> sendOtpLogin(String email) async {
    try {
      final response = await dio.post(
        '/account/warden/send-otp-login-with-sts',
        data: {
          "email": email,
        },
      );
      return response.data;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<String> loginWithEmailOtp(
      {required String email, required String otp}) async {
    try {
      final response = await dio.post(
        '/account/warden/login-otp-sts',
        data: {
          "email": email,
          "otp": otp,
        },
      );
      return response.data['access_token'];
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }

  Future<String> verifyToken(String token) async {
    try {
      final response = await dio.get('/account/warden/verify-azure-ad-token');
      return response.data['access_token'];
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

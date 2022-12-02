import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/models/wardens.dart';

class UserController {
  static final dio = DioHelper.defaultApiClient;
  Future<Wardens> getMe() async {
    try {
      final response = await dio.get('/warden/get-me');
      final wardenFromJson = Wardens.fromJson(response.data);
      print(response.data);
      return wardenFromJson;
    } catch (error) {
      rethrow;
    }
  }

  Future<WardenEvent> createWardenEvent(WardenEvent wardenEvent) async {
    try {
      final response =
          await dio.post('/wardenEvent', data: wardenEvent.toJson());
      final wardenEventFromJson = WardenEvent.fromJson(response.data);
      print(response.data);
      return wardenEventFromJson;
    } catch (error) {
      rethrow;
    }
  }
}

final userController = UserController();

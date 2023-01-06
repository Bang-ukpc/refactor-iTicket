import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';

class UserController {
  static final dio = DioHelper.defaultApiClient;
  Future<Wardens> getMe() async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.get('/warden/get-me');
        final wardenFromJson = Wardens.fromJson(response.data);
        final String encodedData = json.encode(Wardens.toJson(wardenFromJson));
        SharedPreferencesHelper.setStringValue('wardenDataLocal', encodedData);
        return wardenFromJson;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data =
          await SharedPreferencesHelper.getStringValue('wardenDataLocal');
      final wardens = json.decode(data as String) as Map<String, dynamic>;
      print(wardens);
      return Wardens.fromJson(wardens);
    }
  }

  Future<WardenEvent> createWardenEvent(WardenEvent wardenEvent) async {
    try {
      final response =
          await dio.post('/wardenEvent', data: wardenEvent.toJson());
      final wardenEventFromJson = WardenEvent.fromJson(response.data);
      print(response.data);
      return wardenEventFromJson;
    } on DioError catch (error) {
      print(error.response);
      rethrow;
    }
  }
}

final userController = UserController();

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
        final String encodedData = json.encode(wardenFromJson.toJson());
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
      return Wardens.fromJson(wardens);
    }
  }

  Future<WardenEvent> createWardenEvent(WardenEvent wardenEvent) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      if (wardenEvent.Created != null) {
        wardenEvent.Created = wardenEvent.Created;
      } else {
        wardenEvent.Created = DateTime.now();
      }
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
    } else {
      wardenEvent.Created = DateTime.now();
      final String? wardenEventDataLocal =
          await SharedPreferencesHelper.getStringValue('wardenEventDataLocal');
      final String encodedNewData = json.encode(wardenEvent.toJson());

      if (wardenEventDataLocal == null) {
        List<String> newData = [];
        newData.add(encodedNewData);
        final encodedWardenEvent = json.encode(newData);
        SharedPreferencesHelper.setStringValue(
            'wardenEventDataLocal', encodedWardenEvent);
      } else {
        var createdData = json.decode(wardenEventDataLocal) as List<dynamic>;
        createdData.add(encodedNewData);
        final encodedCreatedData = json.encode(createdData);
        SharedPreferencesHelper.setStringValue(
            'wardenEventDataLocal', encodedCreatedData);
      }
      return wardenEvent;
    }
  }
}

final userController = UserController();

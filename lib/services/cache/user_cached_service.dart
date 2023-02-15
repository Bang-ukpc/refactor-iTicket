import 'dart:convert';

import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';

class UserCachedService {
  late String localKey;
  Logger logger = Logger<UserCachedService>();
  UserCachedService() {
    localKey = "User";
  }

  Future<Wardens?> get() async {
    logger.info("get user");
    var strJson = await SharedPreferencesHelper.getStringValue(localKey);
    if (strJson == null) return null;
    var warden = jsonDecodeFactory.decodeJsonStr<Wardens>(strJson);
    logger.info("get user ${warden?.FullName}");
    return warden;
  }

  Future<Wardens> set(Wardens user) async {
    logger.info("set user ${user.FullName}");
    await SharedPreferencesHelper.setStringValue(localKey, json.encode(user));
    var savedUser = await get();
    if (savedUser == null) throw Exception("Save user is not successfully");
    return savedUser;
  }

  Future<void> remove() async {
    logger.info("remove user.");
    return SharedPreferencesHelper.removeStringValue(localKey);
  }
}

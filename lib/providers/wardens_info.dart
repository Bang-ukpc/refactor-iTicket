import 'package:flutter/foundation.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/check_turn_on_net_work.dart';
import 'package:iWarden/helpers/user_info.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';

import '../models/wardens.dart';

class WardensInfo with ChangeNotifier {
  static Wardens? _wardens;
  UserCachedService userCachedService = UserCachedService();
  Wardens? get wardens {
    return _wardens;
  }

  Future<void> getWardensInfoLogging() async {
    final turnOnNetwork = await checkTurnOnNetWork.turnOnWifiAndMobile();

    if (turnOnNetwork) {
      final warden = await userController.getMe();
      await userCachedService.set(warden);
    }

    await userInfo.setUser();
    _wardens = await userCachedService.get();

    notifyListeners();
  }

  void updateWardenInfo(Wardens wardens) {
    _wardens = wardens;
    notifyListeners();
  }
}

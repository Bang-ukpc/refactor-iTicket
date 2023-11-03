import 'package:flutter/foundation.dart';
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
    await userInfo.setUser();
    await userCachedService.get().then((value) {
      if (value != null) {
        _wardens = value;
        notifyListeners();
      }
    });
  }

  void updateWardenInfo(Wardens wardens) {
    _wardens = wardens;
    notifyListeners();
  }
}

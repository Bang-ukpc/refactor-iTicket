import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';

import '../models/wardens.dart';

class WardensInfo with ChangeNotifier {
  static Wardens? _wardens;
  UserCachedService userCachedService = UserCachedService();
  Wardens? get wardens {
    return _wardens;
  }

  Future<void> getWardensInfoLogging() async {
    await userCachedService.get().then((value) {
      if (value != null) {
        _wardens = value;
        notifyListeners();
        FirebaseCrashlytics.instance
            .setCustomKey('userEmail', value.Email.toString());
        FirebaseCrashlytics.instance
            .setCustomKey('version', ConfigEnvironmentVariable.version);
        FirebaseCrashlytics.instance.setUserIdentifier(value.Email.toString());
      }
    });
  }

  void updateWardenInfo(Wardens wardens) {
    _wardens = wardens;
    notifyListeners();
  }
}

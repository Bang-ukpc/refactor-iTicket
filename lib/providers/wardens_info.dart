import 'dart:developer';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:iWarden/controllers/user_controller.dart';
import '../models/wardens.dart';

class WardensInfo with ChangeNotifier {
  static Wardens? _wardens;

  Wardens? get wardens {
    return _wardens;
  }

  Future<void> getWardensInfoLogging() async {
    await userController.getMe().then((value) {
      FirebaseCrashlytics.instance.setCustomKey('userId', value.Id.toString());
      FirebaseCrashlytics.instance.setUserIdentifier(value.Id.toString());
      _wardens = value;
      notifyListeners();
    });
  }

  void updateWardenInfo(Wardens wardens) {
    _wardens = wardens;
    notifyListeners();
  }
}

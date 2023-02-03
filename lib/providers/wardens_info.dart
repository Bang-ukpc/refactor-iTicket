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
      _wardens = value;
      notifyListeners();
      FirebaseCrashlytics.instance
          .setCustomKey('userEmail', value.Email.toString());
      FirebaseCrashlytics.instance.setUserIdentifier(value.Email.toString());
    });
  }

  void updateWardenInfo(Wardens wardens) {
    _wardens = wardens;
    notifyListeners();
  }
}

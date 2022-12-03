import 'package:flutter/foundation.dart';
import 'package:iWarden/controllers/user_controller.dart';
import '../models/wardens.dart';

class WardensInfo with ChangeNotifier {
  static Wardens? _wardens;

  Wardens? get wardens {
    return _wardens;
  }

  Future<void> getWardersInfoLogging() async {
    await userController.getMe().then((value) {
      _wardens = value;
      notifyListeners();
    });
  }
}

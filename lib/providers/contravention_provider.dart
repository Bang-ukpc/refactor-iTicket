import 'package:flutter/foundation.dart';
import 'package:iWarden/models/contravention.dart';

class ContraventionProvider with ChangeNotifier {
  static Contravention? contraventionData;
  static String? colorNullProvider;
  static String? makeNullProvider;

  Contravention? get contravention {
    return contraventionData;
  }

  String? get getColorNullProvider {
    return colorNullProvider;
  }

  String? get getMakeNullProvider {
    return makeNullProvider;
  }

  void setColorNullProvider(String? data) {
    colorNullProvider = data;
    notifyListeners();
  }

  void setMakeNullProvider(String? data) {
    makeNullProvider = data;
    notifyListeners();
  }

  void upDateContravention(Contravention data) {
    contraventionData = data;
    notifyListeners();
  }

  void clearContraventionData() {
    contraventionData = null;
    colorNullProvider = null;
    makeNullProvider = null;
    notifyListeners();
  }
}

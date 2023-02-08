import 'package:flutter/foundation.dart';
import 'package:iWarden/models/contravention.dart';

class ContraventionProvider with ChangeNotifier {
  static int? firstSeenId;
  static Contravention? contraventionData;
  static String? colorNullProvider;
  static String? makeNullProvider;
  static ContraventionReasonTranslations? contraventionCode;

  int? get getFirstSeenId {
    return firstSeenId;
  }

  Contravention? get contravention {
    return contraventionData;
  }

  String? get getColorNullProvider {
    return colorNullProvider;
  }

  String? get getMakeNullProvider {
    return makeNullProvider;
  }

  ContraventionReasonTranslations? get getContraventionCode {
    return contraventionCode;
  }

  void setFirstSeenId(int? id) {
    firstSeenId = id;
    notifyListeners();
  }

  void setColorNullProvider(String? data) {
    colorNullProvider = data;
    notifyListeners();
  }

  void setMakeNullProvider(String? data) {
    makeNullProvider = data;
    notifyListeners();
  }

  void setContraventionCode(ContraventionReasonTranslations? data) {
    contraventionCode = data;
    notifyListeners();
  }

  void upDateContravention(Contravention data) {
    contraventionData = data;
    notifyListeners();
  }

  void clearContraventionData() {
    firstSeenId = null;
    contraventionData = null;
    colorNullProvider = null;
    makeNullProvider = null;
    contraventionCode = null;
    notifyListeners();
  }
}

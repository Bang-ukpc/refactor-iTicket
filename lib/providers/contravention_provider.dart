import 'package:flutter/foundation.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';

class ContraventionProvider with ChangeNotifier {
  static VehicleInformation? vehicleInfoData;
  static Contravention? contraventionData;
  static String? colorNullProvider;
  static String? makeNullProvider;
  static ContraventionReasonTranslations? contraventionCode;

  VehicleInformation? get getVehicleInfo {
    return vehicleInfoData;
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

  void setFirstSeenData(VehicleInformation? vehicleInformation) {
    vehicleInfoData = vehicleInformation;
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
    vehicleInfoData = null;
    contraventionData = null;
    colorNullProvider = null;
    makeNullProvider = null;
    contraventionCode = null;
    notifyListeners();
  }
}

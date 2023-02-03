import 'package:flutter/foundation.dart';
import 'package:iWarden/models/contravention.dart';

class ContraventionProvider with ChangeNotifier {
  static Contravention? contraventionData;
  static String? colorNullProvider;

  Contravention? get contravention {
    return contraventionData;
  }

  String? get getColorNullProvider {
    return colorNullProvider;
  }

  void setColorNullProvider(String? data) {
    colorNullProvider = data;
    notifyListeners();
  }

  void upDateContravention(Contravention data) {
    contraventionData = data;
    notifyListeners();
  }

  void clearContraventionData() {
    contraventionData = null;
    notifyListeners();
  }
}

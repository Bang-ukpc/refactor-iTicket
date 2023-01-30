import 'package:flutter/foundation.dart';
import 'package:iWarden/models/contravention.dart';

class ContraventionProvider with ChangeNotifier {
  static Contravention? contraventionData;

  Contravention? get contravention {
    return contraventionData;
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

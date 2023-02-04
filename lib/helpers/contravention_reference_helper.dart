import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class ContraventionReferenceHelper {
  String getLastTwoDigitsOfYear() {
    int year = DateTime.now().year;
    return year.toString().substring(year.toString().length - 1);
  }

  String paddedDataYear(int numberYearOfDay) {
    return numberYearOfDay.toString().padLeft(3, '0');
  }

  String paddedWardenIDr(int numberYearOfDay) {
    return numberYearOfDay.toString().padLeft(4, '0');
  }

  String getContraventionReference(int wardenID) {
    String prefix = "1";
    String y = getLastTwoDigitsOfYear();
    String hh = DateFormat('hh').format(DateTime.now());
    String mm = DateFormat('mm').format(DateTime.now());
    String yearOfDay = paddedDataYear(Jiffy().dayOfYear);
    return prefix + paddedWardenIDr(wardenID) + y + yearOfDay + hh + mm;
  }
}

final contraventionReferenceHelper = ContraventionReferenceHelper();

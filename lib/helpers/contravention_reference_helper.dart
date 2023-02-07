import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

extension E on String {
  String lastChars(int n) => substring(length - n);
}

class ContraventionReferenceHelper {
  String getLastTwoDigitsOfYear() {
    int year = DateTime.now().year;
    return year.toString().substring(year.toString().length - 1);
  }

  String paddedDataYear(int numberYearOfDay) {
    return numberYearOfDay.toString().padLeft(3, '0');
  }

  String paddedWardenIDr(int numberYearOfDay) {
    var convertToString = numberYearOfDay.toString();
    if (convertToString.length > 4) {
      convertToString = convertToString.lastChars(4);
    }
    return convertToString.padLeft(4, '0');
  }

  String getContraventionReference(
      {required int prefixNumber, required int wardenID}) {
    String prefix = prefixNumber.toString();
    String y = getLastTwoDigitsOfYear();
    String hh = DateFormat('HH').format(DateTime.now());
    String mm = DateFormat('mm').format(DateTime.now());
    String yearOfDay = paddedDataYear(Jiffy().dayOfYear);
    return prefix + paddedWardenIDr(wardenID) + y + yearOfDay + hh + mm;
  }
}

final contraventionReferenceHelper = ContraventionReferenceHelper();

import 'package:iWarden/helpers/user_info.dart';
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
      {required int prefixNumber,
      required int wardenID,
      required DateTime dateTime}) {
    String prefix = userInfo.isStsUser ? '1' : prefixNumber.toString();
    String y = getLastTwoDigitsOfYear();
    String hh = DateFormat('HH').format(dateTime.toUtc());
    String mm = DateFormat('mm').format(dateTime.toUtc());
    String yearOfDay = paddedDataYear(Jiffy().dayOfYear);
    return prefix + paddedWardenIDr(wardenID) + y + yearOfDay + hh + mm;
  }
}

final contraventionReferenceHelper = ContraventionReferenceHelper();

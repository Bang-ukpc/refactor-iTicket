import 'package:intl/intl.dart';

class NumberFormatHelper {
  String getNumberFormat(double number) {
    var formatter = NumberFormat('#,###');
    return formatter.format(number).replaceAll(',', '.');
  }
}

final numberFormatHelper = NumberFormatHelper();

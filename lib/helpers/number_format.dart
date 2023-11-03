import 'package:intl/intl.dart';

class NumberFormatHelper {
  String getNumberFormat(double number) {
    return NumberFormat.decimalPattern().format(number);
  }
}

final numberFormatHelper = NumberFormatHelper();

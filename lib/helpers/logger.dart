import 'package:intl/intl.dart';

class Logger<T> {
  late String key;
  Logger() {
    key = T.runtimeType.toString();
  }

  getTime() {
    return DateFormat('HH:mm yyyy-MM-dd').format(DateTime.now());
  }

  info(Object obj) {
    _log(obj, 'INFO');
  }

  debug(Object obj) {
    _log(obj, 'DEBUG');
  }

  warn(Object obj) {
    _log(obj, 'WARN');
  }

  error(Object obj) {
    _log(obj, 'ERROR');
  }

  _log(Object obj, String level) {
    print("$level  - ${getTime()} - [$key] - $obj");
  }
}

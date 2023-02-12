import 'dart:math';

class IdHelper {
  int generateId() {
    return DateTime.now().microsecondsSinceEpoch.toInt();
  }
}

final idHelper = IdHelper();

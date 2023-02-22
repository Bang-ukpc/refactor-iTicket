import 'package:collection/collection.dart';

class ListHelper {
  static uniqBy<T>(List<T> listT, Function(T t) getKeyFunc) {
    List<T> uniqListT = [];
    for (var t in listT) {
      var isExisted = uniqListT.firstWhereOrNull(
              (element) => getKeyFunc(element) == getKeyFunc(t)) !=
          null;
      if (!isExisted) {
        uniqListT.add(t);
      }
    }
    return uniqListT;
  }
}

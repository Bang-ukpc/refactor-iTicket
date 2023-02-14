class IdHelper {
  int generateId() {
    return -(DateTime.now().microsecondsSinceEpoch.toInt());
  }

  bool isGeneratedByLocal(int? Id) {
    return Id != null && Id < 0;
  }
}

final idHelper = IdHelper();

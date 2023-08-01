import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:iWarden/screens/first-seen/add-first-seen/add_first_seen_screen.dart';

class PickerStore extends ChangeNotifier {
  final int? maxPicture;
  final int minPicture;
  final List<VehicleInfoImage> filesData;

  PickerStore(
      {this.maxPicture, required this.minPicture, required this.filesData});

  bool get canContinue =>
      filesData.length >= minPicture &&
      (maxPicture == null || filesData.length < maxPicture!);

  void addFile(VehicleInfoImage file) async {
    filesData.add(VehicleInfoImage(image: file.image, created: file.created));
    notifyListeners();
  }

  void removeFile(VehicleInfoImage file) async {
    filesData.remove(file);
    notifyListeners();
    try {
      await File(file.image.path).delete();
    } catch (ex) {
      // ignore: avoid_print
      print(ex);
    }
  }
}

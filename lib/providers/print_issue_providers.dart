import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:iWarden/models/ContraventionService.dart';

class PrintIssue {
  final int id;
  final String title;
  File? image;
  DateTime? created;
  PrintIssue({
    required this.id,
    required this.title,
    this.image,
    this.created,
  });
}

class PrintIssueProviders with ChangeNotifier {
  final List<PrintIssue> _data = [
    PrintIssue(id: 1, title: "Vehicle & Background", image: null),
    PrintIssue(id: 2, title: "Screen with ticket on", image: null),
    PrintIssue(id: 3, title: "Close up of contravention", image: null),
    PrintIssue(id: 4, title: "Vehicle & Signage", image: null),
    PrintIssue(id: 5, title: "Signage", image: null),
    PrintIssue(id: 6, title: "Optional photo 1", image: null),
    PrintIssue(id: 7, title: "Optional photo 2", image: null),
    PrintIssue(id: 8, title: "Optional photo 3", image: null),
    PrintIssue(id: 9, title: "Optional photo 4", image: null),
  ];

  // final List<PrintIssue> _data = [
  //   PrintIssue(id: 1, title: "Vehicle & Background", image: null),
  //   PrintIssue(id: 2, title: "Close up of contravention", image: null),
  //   PrintIssue(id: 3, title: "Vehicle & Signage", image: null),
  //   PrintIssue(id: 4, title: "Signage", image: null),
  //   PrintIssue(id: 5, title: "Optional photo 1", image: null),
  //   PrintIssue(id: 6, title: "Optional photo 2", image: null),
  //   PrintIssue(id: 7, title: "Optional photo 3", image: null),
  //   PrintIssue(id: 8, title: "Optional photo 4", image: null),
  // ];

  late int idIssue;

  Future getIdIssue(id) async {
    if (id != null) {
      idIssue = id;
      notifyListeners();
    } else {
      return;
    }
  }

  PrintIssue findIssueNoImage({int? typePCN}) {
    if (typePCN == TypePCN.Virtual.index) {
      var filterImageByVirtual = _data.where((e) => e.id != 2);
      return filterImageByVirtual.firstWhere(
        (element) => element.image == null,
        orElse: () => PrintIssue(
          id: _data.length + 1,
          title: "null",
          image: _data[0].image,
        ),
      );
    }
    return _data.firstWhere(
      (element) => element.image == null,
      orElse: () => PrintIssue(
        id: _data.length + 1,
        title: "null",
        image: _data[0].image,
      ),
    );
  }

  bool checkIssueHasPhotoRequirePhysical() {
    bool check1 = false;
    bool check2 = false;
    bool check3 = false;
    bool check4 = false;
    bool check5 = false;

    for (int i = 0; i < _data.length; i++) {
      if (_data[i].id == 1) {
        if (_data[i].image != null) {
          check1 = true;
        }
      } else if (_data[i].id == 2) {
        if (_data[i].image != null) {
          check2 = true;
        }
      } else if (_data[i].id == 3) {
        if (_data[i].image != null) {
          check3 = true;
        }
      } else if (_data[i].id == 4) {
        if (_data[i].image != null) {
          check4 = true;
        }
      } else if (_data[i].id == 5) {
        if (_data[i].image != null) {
          check5 = true;
        }
      }
    }

    if (check1 == true &&
        check2 == true &&
        check3 == true &&
        check4 == true &&
        check5 == true) {
      return true;
    }
    return false;
  }

  bool checkIssueHasPhotoRequireVirtual() {
    bool check1 = false;
    bool check2 = false;
    bool check3 = false;
    bool check4 = false;

    for (int i = 0; i < _data.length; i++) {
      if (_data[i].id == 1) {
        if (_data[i].image != null) {
          check1 = true;
        }
      } else if (_data[i].id == 3) {
        if (_data[i].image != null) {
          check2 = true;
        }
      } else if (_data[i].id == 4) {
        if (_data[i].image != null) {
          check3 = true;
        }
      } else if (_data[i].id == 5) {
        if (_data[i].image != null) {
          check4 = true;
        }
      }
    }

    if (check1 == true && check2 == true && check3 == true && check4 == true) {
      return true;
    }
    return false;
  }

  void addImageToIssue(int id, File image, DateTime photoCreated) async {
    final PrintIssue temp = _data.firstWhere((element) => element.id == id);
    temp.image = image;
    temp.created = photoCreated;
    notifyListeners();
  }

  late bool checkNullImage = data.every((element) => element.image == null);

  List<PrintIssue> get data {
    return [..._data];
  }

  void resetData() {
    for (int i = 0; i < _data.length; i++) {
      _data[i].image = null;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/providers/locations.dart';

class Contraventions with ChangeNotifier {
  static final contraventionController = ContraventionController();
  Locations? locationsProvider;
  static List<Contravention> contraventionList = [];
  static List<ContraventionReasonTranslations> contraventionReasonList = [];

  Future<List<Contravention>> getContraventionList(
      {int? page, int? pageSize}) async {
    final Pagination list =
        await contraventionController.getContraventionServiceList(
      zoneId: locationsProvider!.zone!.Id as int,
      page: page,
      pageSize: 1000,
    );
    contraventionList =
        list.rows.map((item) => Contravention.fromJson(item)).toList();
    return contraventionList;
  }

  Future<List<ContraventionReasonTranslations>>
      getContraventionReasonList() async {
    final Pagination list =
        await contraventionController.getContraventionReasonServiceList();
    contraventionReasonList = list.rows
        .map((item) => ContraventionReasonTranslations.fromJson(item))
        .toList();
    return contraventionReasonList;
  }

  void update(Locations locations) {
    locationsProvider = locations;
    notifyListeners();
  }
}

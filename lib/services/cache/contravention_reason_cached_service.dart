import 'dart:convert';

import 'package:iWarden/controllers/index.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';

import 'cache_service.dart';

class ContraventionReasonCachedService
    extends CacheService<ContraventionReasonTranslations> {
  late int _zoneId;

  ContraventionReasonCachedService(int zoneId)
      : super("cachedContraventionReasons_$zoneId") {
    _zoneId = zoneId;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkContraventionController
        .getContraventionReasonServiceList(zoneId: _zoneId)
        .catchError((err) async {
      var cachedItems = await getAll();
      return Pagination(
          page: 0,
          pageSize: 1000,
          total: cachedItems.length,
          totalPages: 1,
          rows: cachedItems);
    });
    await set(paging.rows as List<ContraventionReasonTranslations>);
    return paging.rows as List<ContraventionReasonTranslations>;
  }
}

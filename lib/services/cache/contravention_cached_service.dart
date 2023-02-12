import '../../controllers/index.dart';
import '../../models/contravention.dart';
import '../../models/pagination.dart';
import 'cache_service.dart';

class ContraventionCachedService extends CacheService<Contravention> {
  late int _zoneId;
  ContraventionCachedService(int zoneId)
      : super("cachedContraventions_$zoneId") {
    _zoneId = zoneId;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkContraventionController
        .getContraventionServiceList(zoneId: _zoneId, page: 1, pageSize: 1000)
        .catchError((err) async {
      var cachedItems = await getAll();
      return Pagination(
          page: 0,
          pageSize: 1000,
          total: cachedItems.length,
          totalPages: 1,
          rows: cachedItems);
    });
    var contraventions =
        paging.rows.map((e) => Contravention.fromJson(e)).toList();
    set(contraventions);
    return contraventions;
  }
}

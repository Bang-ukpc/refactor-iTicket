import '../../controllers/contravention_controller.dart';
import '../../models/contravention.dart';
import 'cache_service.dart';

class PCNCachedService extends CacheService<Contravention> {
  late int zoneId;
  PCNCachedService(int initZoneId) : super("cachedContraventions_$initZoneId") {
    zoneId = initZoneId;
  }

  @override
  syncFromServer() async {
    var paging = await contraventionController.getContraventionServiceList(
        zoneId: zoneId, page: 1, pageSize: 1000);
    var contraventions = paging.rows as List<Contravention>;
    set(contraventions);
  }
}

import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/models/contravention.dart';
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
    var paging = await contraventionController
        .getContraventionReasonServiceList(zoneId: _zoneId);
    var contraventionReasons = paging.rows;
    var contraventionReasonsFromJson = contraventionReasons
        .map((item) => ContraventionReasonTranslations.fromJson(item))
        .toList();
    set(contraventionReasonsFromJson);
    return contraventionReasonsFromJson;
  }
}

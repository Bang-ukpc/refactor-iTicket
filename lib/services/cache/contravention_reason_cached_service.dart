import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/models/contravention.dart';
import 'cache_service.dart';

class ContraventionReasonCachedService extends CacheService<ContraventionReasonTranslations> {
  ContraventionReasonCachedService() : super("cachedContraventionReasons");

  @override
  syncFromServer() async {
    var paging = await contraventionController.getContraventionReasonServiceList();
    var contraventionReasons = paging.rows as List<ContraventionReasonTranslations>;
    set(contraventionReasons);
  }
}

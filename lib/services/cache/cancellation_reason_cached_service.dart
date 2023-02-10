import 'package:iWarden/controllers/cancellation_reason_controller.dart';

import '../../models/abort_pcn.dart';
import 'cache_service.dart';

class CancellationReasonCachedService extends CacheService<CancellationReason> {
  CancellationReasonCachedService() : super("cachedCancellationReasons");

  @override
  syncFromServer() async {
    var cancellationReasons = await cancellationReasonController.all();
    set(cancellationReasons);
    return cancellationReasons;
  }
}

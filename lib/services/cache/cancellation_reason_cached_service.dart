import 'package:iWarden/controllers/index.dart';

import '../../models/abort_pcn.dart';
import 'cache_service.dart';

class CancellationReasonCachedService extends CacheService<CancellationReason> {
  CancellationReasonCachedService() : super("cachedCancellationReasons");

  @override
  syncFromServer() async {
    var cancellationReasons =
        await weakNetworkCancellationReasonController.all();
    print('[CANCELLATION REASON LENGTH] $cancellationReasons');
    set(cancellationReasons);
    return cancellationReasons;
  }
}

import 'package:iWarden/controllers/index.dart';

import '../../models/abort_pcn.dart';
import 'cache_service.dart';

class CancellationReasonCachedService extends CacheService<CancellationReason> {
  CancellationReasonCachedService() : super("cachedCancellationReasons");

  @override
  syncFromServer() async {
    var cancellationReasons = await weakNetworkCancellationReasonController
        .getAll()
        .catchError((err) async {
      return await getAll();
    });
    print('[CANCELLATION REASON LENGTH] ${cancellationReasons.length}');
    set(cancellationReasons);
    return cancellationReasons;
  }
}

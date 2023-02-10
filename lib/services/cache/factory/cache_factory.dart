import 'package:iWarden/services/cache/cancellation_reason_cached_service.dart';
import 'package:iWarden/services/cache/rota_with_location_cached_service.dart';

import '../contravention_reason_cached_service.dart';

class CachedServiceFactory {
  late CancellationReasonCachedService cancellationReasonCachedService;
  late RotaWithLocationCachedService rotaWithLocationCachedService;
  late ContraventionReasonCachedService defaultContraventionReasonCachedService;
  late int _wardenId;

  CachedServiceFactory(int wardenId) {
    _wardenId = wardenId;
    cancellationReasonCachedService = CancellationReasonCachedService();
    rotaWithLocationCachedService = RotaWithLocationCachedService(_wardenId);
    defaultContraventionReasonCachedService =
        ContraventionReasonCachedService(0);
  }
}

final cachedServiceFactory = CachedServiceFactory(1);

// TODO: Example to sync the data from server
// Future<void> main(List<String> args) async {
//   final cachedServiceFactory = CachedServiceFactory(1);
//   await cachedServiceFactory.rotaWithLocationCachedService.syncFromServer();
//   await cachedServiceFactory.cancellationReasonCachedService.syncFromServer();

//   await cachedServiceFactory.defaultContraventionReasonCachedService.syncFromServer();
//   await cachedServiceFactory.rotaWithLocationCachedService.syncContraventionReasonForAllZones();
// }

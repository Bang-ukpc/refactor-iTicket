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
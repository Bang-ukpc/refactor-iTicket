import 'package:iWarden/services/cache/cancellation_reason_cached_service.dart';

class CachedServiceFactory {
  late CancellationReasonCachedService cancellationReasonCachedService;
  CachedServiceFactory() {
    cancellationReasonCachedService = CancellationReasonCachedService();
  }
}

final cachedServiceFactory = CachedServiceFactory();

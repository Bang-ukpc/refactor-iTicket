import 'package:iWarden/controllers/contravention_reason.dart';
import 'package:iWarden/services/cache/cancellation_reason_cached_service.dart';
import 'package:iWarden/services/cache/contravention_reason_cached_service.dart';
import 'package:iWarden/services/cache/first_seen_cached_service.dart';
import 'package:iWarden/services/cache/grace_period_cached_service.dart';

import '../contravention_cached_service.dart';

class ZoneCachedServiceFactory {
  late int _zoneId;
  late FirstSeenCachedService firstSeenCachedService;
  late GracePeriodCachedService gracePeriodCachedService;
  late ContraventionCachedService contraventionCachedService;
  late ContraventionReasonCachedService contraventionReasonCachedService;

  ZoneCachedServiceFactory(int zoneId) {
    _zoneId = zoneId;
    firstSeenCachedService = FirstSeenCachedService(_zoneId);
    gracePeriodCachedService = GracePeriodCachedService(_zoneId);
    contraventionCachedService = ContraventionCachedService(_zoneId);
    contraventionReasonCachedService = ContraventionReasonCachedService(_zoneId);
  }
}

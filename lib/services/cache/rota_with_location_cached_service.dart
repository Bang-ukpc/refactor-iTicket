import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/services/cache/contravention_reason_cached_service.dart';
import '../../models/location.dart';
import '../../models/zone.dart';
import 'cache_service.dart';

class RotaWithLocationCachedService extends CacheService<RotaWithLocation> {
  late int _wardenId;
  RotaWithLocationCachedService(int wardenId)
      : super("cachedRotaWithLocations") {
    _wardenId = wardenId;
  }

  @override
  syncFromServer() async {
    var filter = ListLocationOfTheDayByWardenIdProps(
        latitude: 0, longitude: 0, wardenId: _wardenId);
    var rotaWithLocations = await locationController.getAll(filter);
    set(rotaWithLocations);
    return rotaWithLocations;
  }

  Future<List<Zone>> _getAllZonesFromRotas() async {
    var rotaWithLocations = await getAll();
    var locations = rotaWithLocations
        .map((e) => e.locations ?? [])
        .toList()
        .reduce((allLocations, locations) => [...allLocations, ...locations]);

    var zones = locations
        .map((l) => l.Zones ?? [])
        .reduce((allZones, zones) => [...allZones, ...zones]);
    return zones;
  }

  syncContraventionReasonForAllZones(
      void Function(int total, int processingIndex)? progressCallback) async {
    var zones = await _getAllZonesFromRotas();
    for (int i = 0; i < zones.length; i++) {
      var zone = zones[i];
      progressCallback!(zones.length, i);
      var contraventionReasonCachedService =
          ContraventionReasonCachedService(zone.Id ?? 0);
      await contraventionReasonCachedService.syncFromServer();
    }
  }
}

import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/index.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/cache/contravention_reason_cached_service.dart';

import '../../models/location.dart';
import '../../models/zone.dart';
import 'cache_service.dart';

class RotaWithLocationCachedService extends CacheService<RotaWithLocation> {
  late int _wardenId;
  Logger logger = Logger<RotaWithLocationCachedService>();
  RotaWithLocationCachedService(int wardenId)
      : super("cachedRotaWithLocations") {
    _wardenId = wardenId;
  }

  @override
  syncFromServer() async {
    var filter = ListLocationOfTheDayByWardenIdProps(
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: _wardenId,
    );
    var rotaWithLocations =
        await weakNetworkRotaWithLocationController.getAll(filter);
    print('[Rota] ${rotaWithLocations.length}');
    await set(rotaWithLocations);
    return rotaWithLocations;
  }

  Future<List<Zone>> _getAllZonesFromRotas() async {
    var rotaWithLocations = await getAll();
    if (rotaWithLocations.isNotEmpty) {
      var groupLocations =
          rotaWithLocations.map((e) => e.locations ?? []).toList();

      var locations = groupLocations
          .reduce((allLocations, locations) => [...allLocations, ...locations]);

      List<Zone> zones = locations
          .map((l) => l.Zones ?? [])
          .where((zones) => zones.isNotEmpty)
          .expand((zones) => zones)
          .toList();

      return zones;
    }
    return [];
  }

  Future<List<LocationWithZones>> getAllLocations() async {
    var rotaWithLocations = await getAll();
    if (rotaWithLocations.isNotEmpty) {
      var groupLocations =
          rotaWithLocations.map((e) => e.locations ?? []).toList();

      var locations = groupLocations
          .reduce((allLocations, locations) => [...allLocations, ...locations]);

      return locations;
    }
    return [];
  }

  syncContraventionReasonForAllZones(
      {void Function(int total, int processingIndex)? progressCallback}) async {
    var zones = await _getAllZonesFromRotas();
    for (int i = 0; i < zones.length; i++) {
      var zone = zones[i];
      if (progressCallback != null) {
        progressCallback(zones.length, i);
      }
      var contraventionReasonCachedService =
          ContraventionReasonCachedService(zone.Id ?? 0);
      await contraventionReasonCachedService.syncFromServer();
    }
  }
}

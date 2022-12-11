import 'package:flutter/foundation.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/zone.dart';

class Locations with ChangeNotifier {
  static LocationWithZones? locationSelected;
  static Zone? zoneSelected;

  LocationWithZones? get location {
    return locationSelected;
  }

  Zone? get zone {
    return zoneSelected;
  }

  int get expiringTimeFirstSeen {
    final secondsOfLocations =
        ((zoneSelected?.Services?[0].ServiceConfig.FirstSeenPeriod ?? 0) +
                (zoneSelected?.Services?[0].ServiceConfig.GracePeriod ?? 0)) *
            60;

    return secondsOfLocations;
  }

  int get expiringTimeGracePeriod {
    final secondsOfLocations =
        ((zoneSelected?.Services?[0].ServiceConfig.GracePeriod ?? 0)) * 60;

    return secondsOfLocations;
  }

  void onSelectedLocation(LocationWithZones? location) {
    locationSelected = location;
    notifyListeners();
  }

  Future<List<Zone>> onSuggestZone(String value) async {
    final List<Zone> zoneList = locationSelected?.Zones ?? [];
    final zones = zoneList
        .where(
          (zone) => zone.Name.toLowerCase().contains(
            value.toLowerCase(),
          ),
        )
        .toList();
    return zones;
  }

  void onSelectedZone(Zone? zone) {
    zoneSelected = zone;
    notifyListeners();
  }

  void resetLocationWithZones() {
    locationSelected = null;
    zoneSelected = null;
    notifyListeners();
  }
}

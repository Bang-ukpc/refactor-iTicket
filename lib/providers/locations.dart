import 'package:flutter/foundation.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/zone.dart';

class Locations with ChangeNotifier {
  static RotaWithLocation? rotaShiftSelected;
  static LocationWithZones? locationSelected;
  static Zone? zoneSelected;

  RotaWithLocation? get rotaShift {
    return rotaShiftSelected;
  }

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

  void onSelectedRotaShift(RotaWithLocation? rotaShift) {
    rotaShiftSelected = rotaShift;
    notifyListeners();
  }

  void onSelectedLocation(LocationWithZones? location) {
    locationSelected = location;
    notifyListeners();
  }

  void onSelectedZone(Zone? zone) {
    zoneSelected = zone;
    notifyListeners();
  }

  void resetLocationWithZones() {
    rotaShiftSelected = null;
    locationSelected = null;
    zoneSelected = null;
    notifyListeners();
  }
}

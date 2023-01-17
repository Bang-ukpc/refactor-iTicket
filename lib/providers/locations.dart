import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
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
    if (rotaShift != null) {
      final String encodedRotaShiftData =
          json.encode(RotaWithLocation.toJson(rotaShift));
      SharedPreferencesHelper.setStringValue(
          'rotaShiftSelectedByWarden', encodedRotaShiftData);
    }
    notifyListeners();
  }

  void onSelectedLocation(LocationWithZones? location) {
    locationSelected = location;
    if (location != null) {
      final String encodedLocationData =
          json.encode(LocationWithZones.toJson(location));
      SharedPreferencesHelper.setStringValue(
          'locationSelectedByWarden', encodedLocationData);
    }
    notifyListeners();
  }

  void onSelectedZone(Zone? zone) {
    zoneSelected = zone;
    if (zone != null) {
      final String encodedZoneData = json.encode(Zone.toJson(zone));
      SharedPreferencesHelper.setStringValue(
          'zoneSelectedByWarden', encodedZoneData);
    }
    notifyListeners();
  }

  void resetLocationWithZones() {
    rotaShiftSelected = null;
    locationSelected = null;
    zoneSelected = null;
    notifyListeners();
  }
}

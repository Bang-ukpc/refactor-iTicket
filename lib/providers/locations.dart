import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/zone.dart';

class Locations with ChangeNotifier {
  static final locationController = LocationController();
  List<LocationWithZones> locationList = [];
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

  Future<List<LocationWithZones>> getLocationList({
    required ListLocationOfTheDayByWardenIdProps
        listLocationOfTheDayByWardenIdProps,
  }) async {
    locationList =
        await locationController.getAll(listLocationOfTheDayByWardenIdProps);
    return locationList;
  }

  // Future<List<LocationWithZones>> onSuggestLocation(String value) async {
  //   final List<LocationWithZones> locationList =
  //       await locationController.getAll();
  //   final locations = locationList
  //       .where(
  //         (location) => location.Name.toLowerCase().contains(
  //           value.toLowerCase(),
  //         ),
  //       )
  //       .toList();
  //   return locations;
  // }

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

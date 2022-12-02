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

  int get expiringTime {
    // final secondsOfLocations =
    //     (zoneSelected?.TimeLimit ?? 0) + (zoneSelected!.GracePeriod ?? 0);
    const secondsOfLocations = 2400;
    return secondsOfLocations;
  }

  Future<List<LocationWithZones>> getLocationList(
      {required int wardenId}) async {
    locationList = await locationController.getAll(wardenId: wardenId);
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

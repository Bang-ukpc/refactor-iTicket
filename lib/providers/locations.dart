import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/helpers/user_info.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/zone.dart';
import 'package:iWarden/services/cache/factory/cache_factory.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';

class Locations with ChangeNotifier {
  static final logger = Logger<Locations>();
  static RotaWithLocation? rotaShiftSelected;
  static LocationWithZones? locationSelected;
  static Zone? zoneSelected;
  late ZoneCachedServiceFactory zoneCachedServiceFactory;
  final CachedServiceFactory cachedServiceFactory =
      CachedServiceFactory(userInfo.user?.Id ?? 0);

  RotaWithLocation? get rotaShift {
    return rotaShiftSelected;
  }

  LocationWithZones? get location {
    return locationSelected;
  }

  ZoneCachedServiceFactory? get getZoneCachedServiceFactory {
    return zoneCachedServiceFactory;
  }

  Zone? get zone {
    return zoneSelected;
  }

  int get expiringTimeFirstSeen {
    final secondsOfLocations =
        (zoneSelected?.Services?[0].ServiceConfig.FirstSeenPeriod ?? 0) * 60;

    return secondsOfLocations;
  }

  int get expiringTimeGracePeriod {
    final secondsOfLocations =
        (zoneSelected?.Services?[0].ServiceConfig.GracePeriod ?? 0) * 60;

    return secondsOfLocations;
  }

  void onSelectedRotaShift(RotaWithLocation? rotaShift) {
    rotaShiftSelected = rotaShift;
    if (rotaShift != null) {
      final String encodedRotaShiftData = json.encode(rotaShift.toJson());
      SharedPreferencesHelper.setStringValue(
          PreferencesKeys.rotaShiftSelectedByWarden, encodedRotaShiftData);
    }
    notifyListeners();
  }

  void onSelectedLocation(LocationWithZones? location) {
    locationSelected = location;
    if (location != null) {
      final String encodedLocationData = json.encode(location.toJson());
      SharedPreferencesHelper.setStringValue(
          PreferencesKeys.locationSelectedByWarden, encodedLocationData);
    }

    notifyListeners();
  }

  void onSelectedZone(Zone? zone) {
    zoneSelected = zone;
    if (zone != null) {
      final String encodedZoneData = json.encode(zone.toJson());
      SharedPreferencesHelper.setStringValue(
          PreferencesKeys.zoneSelectedByWarden, encodedZoneData);
    }
    zoneCachedServiceFactory = ZoneCachedServiceFactory(zone!.Id ?? 0);
    notifyListeners();
  }

  Future<void> onResetLocationAndZone() async {
    List<RotaWithLocation> rotas = [];
    List<LocationWithZones> locationList = [];

    try {
      await cachedServiceFactory.rotaWithLocationCachedService.syncFromServer();
      if (userInfo.isStsUser) {
        locationList = await cachedServiceFactory.rotaWithLocationCachedService
            .getAllLocations();
      } else {
        rotas =
            await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      }
    } catch (e) {
      if (userInfo.isStsUser) {
        locationList = await cachedServiceFactory.rotaWithLocationCachedService
            .getAllLocations();
      } else {
        rotas =
            await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      }
    }

    if (userInfo.isStsUser) {
      logger.info("[IS STS USER] ${userInfo.isStsUser}");
      final selectedLocation = locationList.firstWhereOrNull(
        (l) => l.Id == location?.Id,
      );
      logger.info(selectedLocation != null
          ? "[LOCATION] ${selectedLocation.toJson()}"
          : "Not have location");
      onSelectedLocation(selectedLocation);
      var zoneSelected =
          selectedLocation?.Zones?.firstWhereOrNull((e) => e.Id == zone?.Id);
      logger.info(zoneSelected != null
          ? "[ZONE] ${zoneSelected.toJson()}"
          : "Not have zone");
      onSelectedZone(zoneSelected);
      return;
    } else {
      logger.info("[IS STS USER] ${userInfo.isStsUser}");
      for (final rota in rotas) {
        final selectedLocation = rota.locations!.firstWhereOrNull(
          (l) => l.Id == location?.Id,
        );

        if (selectedLocation != null) {
          logger.info("[LOCATION] ${selectedLocation.toJson()}");
          onSelectedLocation(selectedLocation);
          final zoneSelected = selectedLocation.Zones!.firstWhereOrNull(
            (z) => z.Id == zone?.Id,
          );
          logger.info(zoneSelected != null
              ? "[ZONE] ${zoneSelected.toJson()}"
              : "Not have zone");
          onSelectedZone(zoneSelected);
          return;
        }
      }
    }
  }

  void resetLocationWithZones() {
    rotaShiftSelected = null;
    locationSelected = null;
    zoneSelected = null;
    notifyListeners();
  }
}

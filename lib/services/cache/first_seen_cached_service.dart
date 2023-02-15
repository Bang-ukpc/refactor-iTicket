import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:iWarden/helpers/time_helper.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/services/cache/contravention_cached_service.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';

import '../../controllers/index.dart';
import 'cache_service.dart';

class FirstSeenCachedService extends CacheService<VehicleInformation> {
  late int _zoneId;
  FirstSeenCachedService(int zoneId) : super("cacheFirstSeenItems_$zoneId") {
    _zoneId = zoneId;
  }

  Future<List<VehicleInformation>> getListActive() async {
    var items = await getAllWithCreatedOnTheOffline();
    return items.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  DateTime.now(),
                ),
              ),
            ),
            i.ExpiredAt,
          ) >
          0;
    }).toList();
  }

  Future<List<VehicleInformation>> getListExpired() async {
    var items = await getAllWithCreatedOnTheOffline();
    return items.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  DateTime.now(),
                ),
              ),
            ),
            i.ExpiredAt,
          ) <=
          0;
    }).toList();
  }

  Future<bool> isExisted(String plate) async {
    var cachedItems = await getAll();
    var issuedItem = await createdVehicleDataLocalService.getAllFirstSeen();
    var items = [...issuedItem, ...cachedItems];
    return items.firstWhereOrNull((element) => element.Plate == plate) != null;
  }

  Future<bool> isExistsWithOverStayingInPCNs({
    required String vrn,
    required int zoneId,
  }) async {
    var contraventionCachedService = ContraventionCachedService(zoneId);
    var contraventionList =
        await contraventionCachedService.getAllWithCreatedOnTheOffline();
    var findVRNExits = contraventionList.firstWhereOrNull(
        (e) => e.plate == vrn && e.zoneId == zoneId && e.reason?.code == '36');
    if (findVRNExits != null) {
      var date = DateTime.now();
      var timeMayIssue = findVRNExits.created!.add(const Duration(hours: 24));
      if (date.isBefore(timeMayIssue)) {
        return false;
      }
    }
    return true;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkVehicleInfoController
        .getVehicleInfoList(
            vehicleInfoType: VehicleInformationType.FIRST_SEEN.index,
            zoneId: _zoneId,
            page: 1,
            pageSize: 1000)
        .catchError((err) async {
      var vehicleInfos = await getAll();
      return Pagination(
          page: 0,
          pageSize: 1000,
          total: vehicleInfos.length,
          totalPages: 1,
          rows: vehicleInfos);
    });
    await set(paging.rows as List<VehicleInformation>);
    return paging.rows as List<VehicleInformation>;
  }

  Future<List<VehicleInformation>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItem = await createdVehicleDataLocalService.getAllFirstSeen();
    var cachedAllVehicleInfo = [...issuedItem, ...cachedItems]
        .where((e) => e.CarLeft != true)
        .toList();
    var cachedAllVehicleInfoSort = cachedAllVehicleInfo
      ..sort((i1, i2) => i2.Created!.compareTo(i1.Created!));
    // TODO: sort by created as desc
    return cachedAllVehicleInfoSort;
  }
}

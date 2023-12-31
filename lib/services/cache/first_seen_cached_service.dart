import 'package:collection/collection.dart';
import 'package:iWarden/helpers/list_helper.dart';
import 'package:iWarden/helpers/time_helper.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/services/cache/contravention_cached_service.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';

import '../../controllers/index.dart';
import '../../helpers/logger.dart';
import 'cache_service.dart';

class FirstSeenCachedService extends CacheService<VehicleInformation> {
  late int _zoneId;
  Logger logger = Logger<FirstSeenCachedService>();
  FirstSeenCachedService(int zoneId) : super("cacheFirstSeenItems_$zoneId") {
    _zoneId = zoneId;
  }

  Future<List<VehicleInformation>> getListActive() async {
    var items = await getAllWithCreatedOnTheOffline();
    return filterListActive(items);
  }

  Future<List<VehicleInformation>> filterListActive(
      List<VehicleInformation> list) async {
    DateTime now = await timeNTP.get();
    return list.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  now,
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
    return filterListExpired(items);
  }

  Future<List<VehicleInformation>> filterListExpired(
      List<VehicleInformation> list) async {
    DateTime now = await timeNTP.get();
    return list.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  now,
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
    var issuedItem =
        await createdVehicleDataLocalService.getAllFirstSeen(_zoneId);
    var items = [...issuedItem, ...cachedItems];
    return items.firstWhereOrNull((element) =>
            element.Plate.toLowerCase() == plate.toLowerCase() &&
            element.CarLeftAt == null) !=
        null;
  }

  Future<bool> isExistsWithOverStayingInPCNs({
    required String vrn,
    required int zoneId,
  }) async {
    var contraventionCachedService = ContraventionCachedService(zoneId);
    var contraventionList =
        await contraventionCachedService.getAllWithCreatedOnTheOffline();
    var findVRNExits = contraventionList.firstWhereOrNull((e) =>
        e.plate?.toLowerCase() == vrn.toLowerCase() &&
        e.zoneId == zoneId &&
        e.reason?.code == '36');
    if (findVRNExits != null) {
      var date = await timeNTP.get();
      var timeMayIssue = findVRNExits.created!.add(const Duration(hours: 24));
      if (date.isBefore(timeMayIssue)) {
        return false;
      }
    }
    return true;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkVehicleInfoController.getVehicleInfoList(
        vehicleInfoType: VehicleInformationType.FIRST_SEEN.index,
        zoneId: _zoneId,
        page: 1,
        pageSize: 1000);

    await set(paging.rows as List<VehicleInformation>);
    return paging.rows as List<VehicleInformation>;
  }

  Future<List<VehicleInformation>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItems =
        await createdVehicleDataLocalService.getAllFirstSeen(_zoneId);

    logger.info('items 1 ${cachedItems.map((e) => e.CarLeftAt)}');
    logger.info('items 2 ${issuedItems.map((e) => e.CarLeftAt)}');
    var allItems = [...issuedItems, ...cachedItems];
    allItems = ListHelper.uniqBy<VehicleInformation>(allItems,
        (t) => '${t.ZoneId}_${t.Plate}_${t.Created?.toIso8601String()}');
    logger.info('items 3 ${allItems.map((e) => e.CarLeftAt)}');

    allItems = allItems.where((e) => e.CarLeftAt == null).toList();
    var sortedAllItems = allItems
      ..sort((i1, i2) => i2.Created!.compareTo(i1.Created!));
    logger.info('items 4 ${sortedAllItems.map((e) => e.CarLeftAt)}');

    return sortedAllItems;
  }
}

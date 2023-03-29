import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/time_ntp.dart';

import '../../controllers/index.dart';
import '../../helpers/list_helper.dart';
import '../../helpers/time_helper.dart';
import '../local/created_vehicle_data_local_service.dart';
import 'cache_service.dart';

class GracePeriodCachedService extends CacheService<VehicleInformation> {
  late int _zoneId;
  GracePeriodCachedService(int initZoneId)
      : super("cachedGracePeriodItems_$initZoneId") {
    _zoneId = initZoneId;
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

  Future<List<VehicleInformation>> getListActive() async {
    var items = await getAllWithCreatedOnTheOffline();
    return filterListActive(items);
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

  Future<List<VehicleInformation>> getListExpired() async {
    var items = await getAllWithCreatedOnTheOffline();
    return filterListExpired(items);
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkVehicleInfoController.getVehicleInfoList(
        vehicleInfoType: VehicleInformationType.GRACE_PERIOD.index,
        zoneId: _zoneId,
        page: 1,
        pageSize: 1000);
    var vehicleInfos = paging.rows as List<VehicleInformation>;
    await set(vehicleInfos);
    return vehicleInfos;
  }

  Future<List<VehicleInformation>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItem =
        await createdVehicleDataLocalService.getAllGracePeriod(_zoneId);
    var allItems = [...issuedItem, ...cachedItems];
    allItems = ListHelper.uniqBy<VehicleInformation>(allItems,
        (t) => '${t.ZoneId}_${t.Plate}_${t.Created?.toIso8601String()}');

    allItems = allItems.where((e) => e.CarLeftAt == null).toList();
    var sortedAllItems = allItems
      ..sort((i1, i2) => i2.Created!.compareTo(i1.Created!));
    return sortedAllItems;
  }
}

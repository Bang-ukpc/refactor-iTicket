import 'package:iWarden/models/vehicle_information.dart';
import '../../controllers/index.dart';
import '../../helpers/time_helper.dart';
import '../../models/pagination.dart';
import '../local/created_vehicle_data_local_service.dart';
import 'cache_service.dart';

class GracePeriodCachedService extends CacheService<VehicleInformation> {
  late int _zoneId;
  GracePeriodCachedService(int initZoneId)
      : super("cachedGracePeriodItems_$initZoneId") {
    _zoneId = initZoneId;
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
    var cachedAllVehicleInfo = [...issuedItem, ...cachedItems]
        .where((e) => e.CarLeft != true)
        .toList();
    return cachedAllVehicleInfo;
  }
}

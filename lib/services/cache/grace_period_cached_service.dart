import 'package:iWarden/models/vehicle_information.dart';
import '../../controllers/index.dart';
import '../../models/pagination.dart';
import '../local/created_vehicle_data_local_service.dart';
import 'cache_service.dart';

class GracePeriodCachedService extends CacheService<VehicleInformation> {
  late int zoneId;
  GracePeriodCachedService(int initZoneId) : super("cachedGracePeriodItems_$initZoneId") {
    zoneId = initZoneId;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkVehicleInfoController
        .getVehicleInfoList(
            vehicleInfoType: VehicleInformationType.GRACE_PERIOD.index,
            zoneId: zoneId,
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
    var vehicleInfos = paging.rows as List<VehicleInformation>;
    set(vehicleInfos);
    return vehicleInfos;
  }

  getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItem = await createdVehicleDataLocalService.getAllGracePeriod();
    return cachedItems.addAll(issuedItem);
  }
}

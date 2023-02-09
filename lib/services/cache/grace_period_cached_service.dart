import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/models/vehicle_information.dart';

import 'cache_service.dart';

class GracePeriodCachedService extends CacheService<VehicleInformation> {
  late int zoneId;
  GracePeriodCachedService(int initZoneId) : super("cachedGracePeriodItems") {
    zoneId = initZoneId;
  }

  @override
  syncFromServer() async {
    var paging = await vehicleInfoController.getVehicleInfoList(
        vehicleInfoType: VehicleInformationType.GRACE_PERIOD.index,
        zoneId: zoneId,
        page: 1,
        pageSize: 1000);
    var vehicleInfos = paging.rows as List<VehicleInformation>;
    set(vehicleInfos);
  }
}

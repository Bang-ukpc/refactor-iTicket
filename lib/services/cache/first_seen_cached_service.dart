import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/models/vehicle_information.dart';

import 'cache_service.dart';

class FirstSeenCachedService extends CacheService<VehicleInformation> {
  late int zoneId;
  FirstSeenCachedService(int initZoneId) : super("cacheFirstSeenItems") {
    zoneId = initZoneId;
  }

  @override
  syncFromServer() async {
    var paging = await vehicleInfoController.getVehicleInfoList(
        vehicleInfoType: VehicleInformationType.FIRST_SEEN.index,
        zoneId: zoneId,
        page: 1,
        pageSize: 1000);
    var firstSeenItems = paging.rows as List<VehicleInformation>;
    set(firstSeenItems);
    return firstSeenItems;
  }
}

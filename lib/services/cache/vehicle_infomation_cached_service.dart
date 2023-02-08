import 'package:iWarden/models/vehicle_information.dart';

import 'cache_service.dart';

class VehicleInformationCachedService extends CacheService<VehicleInformation> {
  VehicleInformationCachedService() : super("VehicleInformation");
}
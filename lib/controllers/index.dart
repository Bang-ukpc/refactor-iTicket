import 'package:iWarden/controllers/vehicle_information_controller.dart';

import '../helpers/dio_helper.dart';

final vehicleInfoController = VehicleInfoController(DioHelper.defaultApiClient);
final weakNetworkVehicleInfoController = VehicleInfoController(DioHelper.weakNetWorkApiClient);

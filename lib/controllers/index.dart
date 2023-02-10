import 'package:iWarden/controllers/vehicle_information_controller.dart';

import '../helpers/dio_helper.dart';

final vehicleInfoController = VehicleInfoController.fromDio(DioHelper.defaultApiClient);
final weakNetworkVehicleInfoController = VehicleInfoController.fromDio(DioHelper.weakNetWorkApiClient);

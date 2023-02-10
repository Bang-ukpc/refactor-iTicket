import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';

import '../helpers/dio_helper.dart';

final vehicleInfoController = VehicleInfoController.fromDio(DioHelper.defaultApiClient);
final weakNetworkVehicleInfoController = VehicleInfoController.fromDio(DioHelper.weakNetWorkApiClient);
final weakNetworkContraventionController = ContraventionController.fromDio(DioHelper.weakNetWorkApiClient);

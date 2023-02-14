import 'package:iWarden/controllers/cancellation_reason_controller.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';

import '../helpers/dio_helper.dart';

final weakNetworkCancellationReasonController =
    CancellationReasonController.fromDio(DioHelper.weakNetWorkApiClient);
final weakNetworkRotaWithLocationController =
    LocationController.fromDio(DioHelper.weakNetWorkApiClient);
final weakNetworkVehicleInfoController =
    VehicleInfoController.fromDio(DioHelper.weakNetWorkApiClient);
final weakNetworkContraventionController =
    ContraventionController.fromDio(DioHelper.weakNetWorkApiClient);
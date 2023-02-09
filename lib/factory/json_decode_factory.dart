import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';

import '../models/ContraventionService.dart';

class JsonDecodeFactory {
  T? decode<T>(Map<String, dynamic> json) {
    if (T == VehicleInformation) return VehicleInformation.fromJson(json) as T;
    if (T == ContraventionCreateWardenCommand)
      return ContraventionCreateWardenCommand.fromJson(json) as T;
    if (T == ContraventionCreatePhoto)
      return ContraventionCreatePhoto.fromJson(json) as T;
    if (T == WardenEvent) return WardenEvent.fromJson(json) as T;
    if (T == ContraventionReasonTranslations)
      return ContraventionReasonTranslations.fromJson(json) as T;

    final className = T.toString();
    throw Exception("$className is not register to the factory");
  }
}

final jsonDecodeFactory = JsonDecodeFactory();

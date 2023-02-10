import 'dart:convert';

import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';

import '../models/ContraventionService.dart';

class JsonDecodeFactory {
  T? decode<T>(Map<String, dynamic> json) {
    if (T == VehicleInformation) return VehicleInformation.fromJson(json) as T;
    if (T == ContraventionCreateWardenCommand) {
      return ContraventionCreateWardenCommand.fromJson(json) as T;
    }
    if (T == ContraventionCreatePhoto) {
      return ContraventionCreatePhoto.fromJson(json) as T;
    }
    if (T == WardenEvent) return WardenEvent.fromJson(json) as T;
    if (T == ContraventionReasonTranslations) {
      return ContraventionReasonTranslations.fromJson(json) as T;
    }
    if (T == CancellationReason) return CancellationReason.fromJson(json) as T;
    if (T == EvidencePhoto) return EvidencePhoto.fromJson(json) as T;
    final className = T.toString();
    throw Exception("$className is not register to the factory");
  }

  List<T> decodeList<T>(List<dynamic> decodedItems) {
    return decodedItems.map((decodedItem) {
      if (decodedItem is String) {
        return decode<T>(json.decode(decodedItem)) as T;
      } else {
        return decode<T>(decodedItem) as T;
      }
    }).toList();
  }

  List<T> decodeListJson<T>(String listJson) {
    var decodedItems = json.decode(listJson) as List<dynamic>;
    return decodedItems.map((decodedItem) {
      if (decodedItem is String) {
        return decode<T>(json.decode(decodedItem)) as T;
      } else {
        return decode<T>(decodedItem) as T;
      }
    }).toList();
  }
}

final jsonDecodeFactory = JsonDecodeFactory();

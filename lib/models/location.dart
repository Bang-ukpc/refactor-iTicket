import 'dart:convert';

import 'package:iWarden/models/base_model.dart';
import 'package:iWarden/models/operational_period.dart';
import 'package:iWarden/models/zone.dart';

class Location extends BaseModel {
  final String Name;
  final String? LocationType;
  final int? CountryRegionId;
  final int CountrySubRegionId;
  final int? ClusterId;
  final double? Longitude;
  final double? Latitude;
  final String? Address;
  final String? Address1;
  final String? Address2;
  final String? Address3;
  final String? Town;
  final String? County;
  final String? Postcode;
  final String? Notes;
  final double? Distance;

  Location({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    this.Address,
    this.Address1,
    this.Address2,
    this.Address3,
    this.Town,
    this.County,
    this.Postcode,
    required this.Name,
    this.LocationType,
    this.CountryRegionId,
    required this.CountrySubRegionId,
    this.ClusterId,
    this.Longitude,
    this.Latitude,
    this.Notes,
    this.Distance,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);
}

class LocationWithZones extends Location {
  final List<Zone>? Zones;
  final List<OperationalPeriod>? OperationalPeriods;
  final double LowerAmount;
  final double UpperAmount;
  LocationWithZones({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    String? Address,
    String? Address1,
    String? Address2,
    String? Address3,
    String? Town,
    String? County,
    String? Postcode,
    required String Name,
    String? LocationType,
    int? CountryRegionId,
    required int CountrySubRegionId,
    int? ClusterId,
    double? Longitude,
    double? Latitude,
    String? Notes,
    double? Distance,
    DateTime? From,
    DateTime? To,
    required this.LowerAmount,
    required this.UpperAmount,
    this.Zones,
    this.OperationalPeriods,
  }) : super(
          Id: Id,
          Created: Created,
          Deleted: Deleted,
          Address: Address,
          Address1: Address1,
          Address2: Address2,
          Address3: Address3,
          Town: Town,
          County: County,
          Postcode: Postcode,
          Name: Name,
          LocationType: LocationType,
          CountryRegionId: CountryRegionId,
          CountrySubRegionId: CountrySubRegionId,
          ClusterId: ClusterId,
          Latitude: Latitude,
          Longitude: Longitude,
          Notes: Notes,
          Distance: Distance,
        );

  factory LocationWithZones.fromJson(Map<String, dynamic> json) =>
      _$LocationWithZonesFromJson(json);

  static Map<String, dynamic> toJson(LocationWithZones locationWithZones) => {
        'Address': locationWithZones.Address,
        'Latitude': locationWithZones.Latitude,
        'Longitude': locationWithZones.Longitude,
        'Created': locationWithZones.Created != null
            ? locationWithZones.Created!.toIso8601String()
            : null,
        'Deleted': locationWithZones.Deleted != null
            ? locationWithZones.Deleted!.toIso8601String()
            : null,
        'Id': locationWithZones.Id,
        'CountryRegionId': locationWithZones.CountryRegionId,
        'CountrySubRegionId': locationWithZones.CountrySubRegionId,
        'Name': locationWithZones.Name,
        'Address1': locationWithZones.Address1,
        'Address2': locationWithZones.Address2,
        'Address3': locationWithZones.Address3,
        'Town': locationWithZones.Town,
        'County': locationWithZones.County,
        'Postcode': locationWithZones.Postcode,
        'LocationType': locationWithZones.LocationType,
        'Notes': locationWithZones.Notes,
        'Zones': locationWithZones.Zones != null
            ? locationWithZones.Zones!.map((v) => Zone.toJson(v)).toList()
            : [],
        'Distance': locationWithZones.Distance,
        'OperationalPeriods': locationWithZones.OperationalPeriods != null
            ? locationWithZones.OperationalPeriods!
                .map((e) => OperationalPeriod.toJson(e))
                .toList()
            : []
      };

  static String encode(List<LocationWithZones> locationWithZones) =>
      json.encode(
        locationWithZones.map((i) => LocationWithZones.toJson(i)).toList(),
      );

  static List<LocationWithZones> decode(String locations) =>
      (json.decode(locations) as List<dynamic>)
          .map<LocationWithZones>((item) => LocationWithZones.fromJson(item))
          .toList();
}

LocationWithZones _$LocationWithZonesFromJson(Map<String, dynamic> json) {
  var zonesFromJson = json['Zones'] as List<dynamic>;
  List<Zone> zonesList = [];
  if (zonesFromJson.isNotEmpty) {
    zonesList = zonesFromJson.map((model) => Zone.fromJson(model)).toList();
  }

  var operationalPeriodsFromJson = json['OperationalPeriods'] as List<dynamic>;
  List<OperationalPeriod> operationalPeriodsList = [];
  if (operationalPeriodsFromJson.isNotEmpty) {
    operationalPeriodsList = operationalPeriodsFromJson
        .map((model) => OperationalPeriod.fromJson(model))
        .toList();
  }
  return LocationWithZones(
    Id: json['Id'],
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    Address: json['Address'],
    Address1: json['Address1'],
    Address2: json['Address2'],
    Address3: json['Address3'],
    Town: json['Town'],
    County: json['County'],
    Postcode: json['Postcode'],
    Name: json['Name'],
    LocationType: json['LocationType'],
    CountryRegionId: json['CountryRegionId'],
    CountrySubRegionId: json['CountrySubRegionId'],
    ClusterId: json['ClusterId'],
    Longitude: json['Longitude'],
    Latitude: json['Latitude'],
    Notes: json['Notes'],
    Distance: json['Distance'],
    Zones: zonesList,
    OperationalPeriods: operationalPeriodsList,
    UpperAmount: json['Rates'] != null
        ? (json['Rates'] as List<dynamic>).isNotEmpty
            ? json['Rates'][0]['UpperAmount'].toDouble()
            : 0
        : 0,
    LowerAmount: json['Rates'] != null
        ? (json['Rates'] as List<dynamic>).isNotEmpty
            ? json['Rates'][0]['LowerAmount'].toDouble()
            : 0
        : 0,
  );
}

class RotaStatus {
  static String get ASSIGNED => "assigned";
  static String get NOT_ASSIGNED => 'not_assigned';
  static String get LIEU_LEAVE => 'lieu_leave';
  static String get OUTSIDE => 'outside';
}

class RotaType {
  static LeaveDayType? leaveDayType;
  static String get work => "work";
}

class LeaveDayType {
  static String get holiday => "holiday";
  static String get other => 'other';
  static String get absent => 'absent';
  static String get unAbsent => 'un-absent';
  static String get lieu => 'lieu';
  static String get sick => 'sick';
}

class Rota extends BaseModel {
  int? wardenId;
  DateTime? timeFrom;
  DateTime? timeTo;
  String? rotaType;

  Rota({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    required this.wardenId,
    required this.timeFrom,
    required this.timeTo,
    this.rotaType,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  Rota.fromJson(Map<String, dynamic> json) {
    Created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    Deleted = json['Deleted'] == null ? null : DateTime.parse(json['Deleted']);
    Id = json['Id'];
    wardenId = json['WardenId'];
    timeFrom = DateTime.parse(json['TimeFrom']);
    timeTo = DateTime.parse(json['TimeTo']);
    rotaType = json['RotaType'];
  }
}

class RotaWithLocation extends Rota {
  List<LocationWithZones>? locations;

  RotaWithLocation({
    this.locations,
    required super.wardenId,
    required super.timeFrom,
    required super.timeTo,
    super.Created,
    super.Deleted,
    super.Id,
    super.rotaType,
  });

  factory RotaWithLocation.fromJson(Map<String, dynamic> json) =>
      _$RotaWithLocationFromJson(json);

  static Map<String, dynamic> toJson(RotaWithLocation rotaWithLocation) => {
        'WardenId': rotaWithLocation.wardenId,
        'Created': rotaWithLocation.Created != null
            ? rotaWithLocation.Created!.toIso8601String()
            : null,
        'Deleted': rotaWithLocation.Deleted != null
            ? rotaWithLocation.Deleted!.toIso8601String()
            : null,
        'Id': rotaWithLocation.Id,
        'TimeFrom': rotaWithLocation.timeFrom!.toIso8601String(),
        'TimeTo': rotaWithLocation.timeTo!.toIso8601String(),
        'RotaType': rotaWithLocation.rotaType,
        'Locations': rotaWithLocation.locations!
            .map((i) => LocationWithZones.toJson(i))
            .toList(),
      };

  static String encode(List<RotaWithLocation> rotaWithLocation) => json.encode(
        rotaWithLocation.map((i) => RotaWithLocation.toJson(i)).toList(),
      );

  static List<RotaWithLocation> decode(String rotaWithLocation) =>
      (json.decode(rotaWithLocation) as List<dynamic>)
          .map<RotaWithLocation>((item) => RotaWithLocation.fromJson(item))
          .toList();
}

RotaWithLocation _$RotaWithLocationFromJson(Map<String, dynamic> json) {
  var locationWithZonesFromJson = json['Locations'] as List<dynamic>;
  List<LocationWithZones> locationWithZones = [];
  if (locationWithZonesFromJson.isNotEmpty) {
    locationWithZones = locationWithZonesFromJson
        .map((model) => LocationWithZones.fromJson(model))
        .toList();
  }

  return RotaWithLocation(
    wardenId: json['WardenId'],
    timeFrom: DateTime.parse(json['TimeFrom']),
    timeTo: DateTime.parse(json['TimeTo']),
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    Id: json['Id'],
    rotaType: json['RotaType'],
    locations: locationWithZones,
  );
}

class ListLocationOfTheDayByWardenIdProps {
  final double latitude;
  final double longitude;
  final int wardenId;

  ListLocationOfTheDayByWardenIdProps({
    required this.latitude,
    required this.longitude,
    required this.wardenId,
  });

  Map<String, dynamic> toJson() =>
      _$ListLocationOfTheDayByWardenIdPropsToJson(this);
}

Map<String, dynamic> _$ListLocationOfTheDayByWardenIdPropsToJson(
    ListLocationOfTheDayByWardenIdProps instance) {
  return <String, dynamic>{
    'Latitude': instance.latitude,
    'Longitude': instance.longitude,
    'WardenId': instance.wardenId,
  };
}

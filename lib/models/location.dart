import 'dart:convert';

import 'package:iWarden/models/base_model.dart';
import 'package:iWarden/models/operational_period.dart';
import 'package:iWarden/models/zone.dart';

class Location extends BaseModel {
  final String Name;
  final String? LocationType;
  final int? Revenue;
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
  final String? Country;
  final String? Postcode;
  final String? Notes;
  final double? Distance;
  final DateTime? From;
  final DateTime? To;

  Location(
      {int? Id,
      DateTime? Created,
      DateTime? Deleted,
      this.Address,
      this.Address1,
      this.Address2,
      this.Address3,
      this.Town,
      this.Country,
      this.Postcode,
      required this.Name,
      this.LocationType,
      this.Revenue,
      this.CountryRegionId,
      required this.CountrySubRegionId,
      this.ClusterId,
      this.Longitude,
      this.Latitude,
      this.Notes,
      this.Distance,
      this.From,
      this.To})
      : super(Id: Id, Created: Created, Deleted: Deleted);
}

class LocationWithZones extends Location {
  final List<Zone>? Zones;
  final List<OperationalPeriod>? OperationalPeriods;

  LocationWithZones({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    String? Address,
    String? Address1,
    String? Address2,
    String? Address3,
    String? Town,
    String? Country,
    String? Postcode,
    required String Name,
    String? LocationType,
    int? Revenue,
    int? CountryRegionId,
    required int CountrySubRegionId,
    int? ClusterId,
    double? Longitude,
    double? Latitude,
    String? Notes,
    double? Distance,
    DateTime? From,
    DateTime? To,
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
          Country: Country,
          Postcode: Postcode,
          Name: Name,
          LocationType: LocationType,
          Revenue: Revenue,
          CountryRegionId: CountryRegionId,
          CountrySubRegionId: CountrySubRegionId,
          ClusterId: ClusterId,
          Latitude: Latitude,
          Longitude: Longitude,
          Notes: Notes,
          Distance: Distance,
          From: From,
          To: To,
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
        'Country': locationWithZones.Country,
        'Postcode': locationWithZones.Postcode,
        'LocationType': locationWithZones.LocationType,
        'Notes': locationWithZones.Notes,
        'Zones': locationWithZones.Zones != null
            ? locationWithZones.Zones!.map((v) => Zone.toJson(v)).toList()
            : [],
        'From': locationWithZones.From != null
            ? locationWithZones.From!.toIso8601String()
            : null,
        'To': locationWithZones.To != null
            ? locationWithZones.To!.toIso8601String()
            : null,
        'Distance': locationWithZones.Distance,
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
  List<Zone> zonesList =
      zonesFromJson.map((model) => Zone.fromJson(model)).toList();

  return LocationWithZones(
    Id: json['Id'],
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    Address: json['Address'],
    Address1: json['Address1'],
    Address2: json['Address2'],
    Address3: json['Address3'],
    Town: json['Town'],
    Country: json['Country'],
    Postcode: json['Postcode'],
    Name: json['Name'],
    LocationType: json['LocationType'],
    Revenue: json['Revenue'],
    CountryRegionId: json['CountryRegionId'],
    CountrySubRegionId: json['CountrySubRegionId'],
    ClusterId: json['ClusterId'],
    Longitude: json['Longitude'],
    Latitude: json['Latitude'],
    Notes: json['Notes'],
    Distance: json['Distance'],
    From: json['From'] == null ? null : DateTime.parse(json['From']),
    To: json['To'] == null ? null : DateTime.parse(json['To']),
    Zones: zonesList,
    OperationalPeriods: json['OperationalPeriods'],
  );
}

class MyRotaShift {
  final DateTime? From;
  final DateTime? To;

  MyRotaShift({this.From, this.To});
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

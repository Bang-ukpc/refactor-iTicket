import 'package:iWarden/models/base_model.dart';

class Wardens extends BaseModel {
  final String? ExternalId;
  final int? CountrySubRegionId;
  final String? FistName;
  final String? LastName;
  final String? FullName;
  final String? Email;
  final String? PhoneNumber;
  final String? Postcode;
  final String? Picture;
  final double? Latitude;
  final double? Longitude;

  const Wardens({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    this.ExternalId,
    this.CountrySubRegionId,
    this.FistName,
    this.LastName,
    this.FullName,
    this.Email,
    this.PhoneNumber,
    this.Postcode,
    this.Picture,
    this.Latitude,
    this.Longitude,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory Wardens.fromJson(Map<String, dynamic> json) =>
      _$WardensFromJson(json);

  static Map<String, dynamic> toJson(Wardens wardens) => {
        'Id': wardens.Id,
        'Created':
            wardens.Created != null ? wardens.Created!.toIso8601String() : null,
        'Deleted':
            wardens.Deleted != null ? wardens.Deleted!.toIso8601String() : null,
        'ExternalId': wardens.ExternalId,
        'CountrySubRegionId': wardens.CountrySubRegionId,
        'FistName': wardens.FistName,
        'LastName': wardens.LastName,
        'FullName': wardens.FullName,
        'Email': wardens.Email,
        'PhoneNumber': wardens.PhoneNumber,
        'Postcode': wardens.Postcode,
        'Picture': wardens.Picture,
        'Latitude': wardens.Latitude,
        'Longitude': wardens.Longitude,
      };
}

Wardens _$WardensFromJson(Map<String, dynamic> json) => Wardens(
      Id: json['Id'],
      Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
      Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
      ExternalId: json['ExternalId'],
      CountrySubRegionId: json['CountrySubRegionId'],
      FistName: json['FistName'],
      LastName: json['LastName'],
      FullName: json['FullName'],
      Email: json['Email'],
      PhoneNumber: json['PhoneNumber'],
      Postcode: json['Postcode'],
      Picture: json['Picture'],
      Latitude: json['Latitude'] == null ? 0 : json['Latitude'].toDouble(),
      Longitude: json['Longitude'] == null ? 0 : json['Longitude'].toDouble(),
    );

class WardenEvent extends BaseModel {
  final int type;
  final String? detail;
  final double? latitude;
  final double? longitude;
  final int wardenId;
  final int? zoneId;
  final int? locationId;

  WardenEvent({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    required this.type,
    this.detail,
    this.latitude,
    this.longitude,
    required this.wardenId,
    this.zoneId,
    this.locationId,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory WardenEvent.fromJson(Map<String, dynamic> json) =>
      _$WardenEventFromJson(json);

  Map<String, dynamic> toJson() => _$WardenEventToJson(this);
}

enum TypeWardenEvent {
  StartShift,
  EndShift,
  CheckIn,
  CheckOut,
  StartBreak,
  EndBreak,
  AddFirstSeen,
  AddGracePeriod,
  TrackGPS,
  IssuePCN,
  AbortPCN,
}

WardenEvent _$WardenEventFromJson(Map<String, dynamic> json) {
  return WardenEvent(
    Id: json['Id'],
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    type: json['Type'],
    detail: json['Detail'],
    latitude: json['Latitude'] == null ? 0 : json['Latitude'].toDouble(),
    longitude: json['Longitude'] == null ? 0 : json['Longitude'].toDouble(),
    wardenId: json['WardenId'],
    zoneId: json['ZoneId'],
    locationId: json['LocationId'],
  );
}

Map<String, dynamic> _$WardenEventToJson(WardenEvent instance) {
  return <String, dynamic>{
    'Type': instance.type,
    'Detail': instance.detail,
    'Latitude': instance.latitude,
    'Longitude': instance.longitude,
    'WardenId': instance.wardenId,
    'ZoneId': instance.zoneId,
    'LocationId': instance.locationId,
  };
}

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

  Wardens({
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

  Map<String, dynamic> toJson() => {
        'Id': Id,
        'Created': Created != null ? Created!.toIso8601String() : null,
        'Deleted': Deleted != null ? Deleted!.toIso8601String() : null,
        'ExternalId': ExternalId,
        'CountrySubRegionId': CountrySubRegionId,
        'FistName': FistName,
        'LastName': LastName,
        'FullName': FullName,
        'Email': Email,
        'PhoneNumber': PhoneNumber,
        'Postcode': Postcode,
        'Picture': Picture,
        'Latitude': Latitude,
        'Longitude': Longitude,
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
  int type;
  String? detail;
  double? latitude;
  double? longitude;
  int wardenId;
  int? zoneId;
  int? locationId;
  DateTime? rotaTimeFrom;
  DateTime? rotaTimeTo;
  int? cancellationReasonId;

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
    this.rotaTimeFrom,
    this.rotaTimeTo,
    this.cancellationReasonId,
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
    rotaTimeFrom: json['RotaTimeFrom'] == null
        ? null
        : DateTime.parse(json['RotaTimeFrom']),
    rotaTimeTo:
        json['RotaTimeTo'] == null ? null : DateTime.parse(json['RotaTimeTo']),
    cancellationReasonId: json['CancellationReasonId'],
  );
}

Map<String, dynamic> _$WardenEventToJson(WardenEvent instance) {
  return <String, dynamic>{
    'Created':
        instance.Created != null ? instance.Created!.toIso8601String() : null,
    'Type': instance.type,
    'Detail': instance.detail,
    'Latitude': instance.latitude,
    'Longitude': instance.longitude,
    'WardenId': instance.wardenId,
    'ZoneId': instance.zoneId,
    'LocationId': instance.locationId,
    'RotaTimeFrom': instance.rotaTimeFrom != null
        ? instance.rotaTimeFrom!.toIso8601String()
        : null,
    'RotaTimeTo': instance.rotaTimeTo != null
        ? instance.rotaTimeTo!.toIso8601String()
        : null,
    'CancellationReasonId': instance.cancellationReasonId,
  };
}

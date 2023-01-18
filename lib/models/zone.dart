import 'package:iWarden/models/base_model.dart';
import 'package:iWarden/models/service.dart';

class Zone extends BaseModel {
  final int LocationId;
  final String Name;
  final String PublicName;
  final List<Service>? Services;
  final String ExternalReference;

  Zone({
    Id,
    Created,
    Deleted,
    required this.LocationId,
    required this.Name,
    required this.PublicName,
    this.Services,
    required this.ExternalReference,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory Zone.fromJson(Map<String, dynamic> json) => _$ZoneFromJson(json);

  static Map<String, dynamic> toJson(Zone zone) => {
        'Created':
            zone.Created != null ? zone.Created!.toIso8601String() : null,
        'Deleted':
            zone.Deleted != null ? zone.Deleted!.toIso8601String() : null,
        'Id': zone.Id,
        'LocationId': zone.LocationId,
        'Name': zone.Name,
        'PublicName': zone.PublicName,
        'ExternalReference': zone.ExternalReference,
        'Services': zone.Services != null
            ? zone.Services!.map((v) => Service.toJson(v)).toList()
            : [],
      };
}

Zone _$ZoneFromJson(Map<String, dynamic> json) {
  var servicesFromJson = json['Services'] as List<dynamic>;
  List<Service> servicesList = [];
  if (servicesFromJson.isNotEmpty) {
    servicesList =
        servicesFromJson.map((model) => Service.fromJson(model)).toList();
  }

  return Zone(
    Id: json['Id'],
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    LocationId: json['LocationId'],
    Name: json['Name'],
    PublicName: json['PublicName'],
    Services: servicesList,
    ExternalReference: json['ExternalReference'],
  );
}

import 'package:iWarden/models/base_model.dart';

enum VehicleInformationType { FIRST_SEEN, GRACE_PERIOD }

class EvidencePhoto extends BaseModel {
  final int? VehicleInformationId;
  late String BlobName;

  EvidencePhoto({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    this.VehicleInformationId,
    required this.BlobName,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory EvidencePhoto.fromJson(Map<String, dynamic> json) =>
      _$EvidencePhotoFromJson(json);

  Map<String, dynamic> toJson() => _$EvidencePhotoToJson(this);
}

EvidencePhoto _$EvidencePhotoFromJson(Map<String, dynamic> json) {
  // print('[VEHICLE INFO] to json evident photo $json');
  return EvidencePhoto(
    VehicleInformationId: json['VehicleInformationId'],
    BlobName: json['BlobName'],
    Id: json['Id'] ?? 0,
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
  );
}

Map<String, dynamic> _$EvidencePhotoToJson(EvidencePhoto instance) {
  return <String, dynamic>{
    'BlobName': instance.BlobName,
    'VehicleInformationId': instance.VehicleInformationId,
    'Id': instance.Id,
    'Created':
        instance.Created != null ? instance.Created!.toIso8601String() : null,
  };
}

class VehicleInformation extends BaseModel {
  DateTime ExpiredAt;
  String Plate;
  int ZoneId;
  int LocationId;
  String BayNumber;
  int Type;
  double Latitude;
  double Longitude;
  DateTime? CarLeftAt;
  List<EvidencePhoto>? EvidencePhotos;

  VehicleInformation({
    Id,
    Created,
    Deleted,
    CreatedBy,
    required this.ExpiredAt,
    required this.Plate,
    required this.ZoneId,
    required this.LocationId,
    required this.BayNumber,
    required this.Type,
    required this.Latitude,
    required this.Longitude,
    this.CarLeftAt,
    this.EvidencePhotos,
  }) : super(Id: Id, Created: Created, Deleted: Deleted, CreatedBy: CreatedBy);

  factory VehicleInformation.fromJson(Map<String, dynamic> json) =>
      _$VehicleInformationFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleInformationToJson(this);
}

VehicleInformation _$VehicleInformationFromJson(Map<String, dynamic> json) {
  List<EvidencePhoto> evidencePhotosList = [];
  if (json['EvidencePhotos'] != null) {
    var evidencePhotosFromJson = json['EvidencePhotos'] as List<dynamic>;
    evidencePhotosList = evidencePhotosFromJson
        .map((model) => EvidencePhoto.fromJson(model))
        .toList();
  }

  return VehicleInformation(
    Id: json['Id'],
    Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
    Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
    ExpiredAt: json['ExpiredAt'] == null
        ? DateTime.now()
        : DateTime.parse(json['ExpiredAt']),
    Plate: json['Plate'],
    ZoneId: json['ZoneId'],
    LocationId: json['LocationId'],
    BayNumber: json['BayNumber'],
    Type: json['Type'],
    Latitude: json['Latitude'].toDouble(),
    Longitude: json['Longitude'].toDouble(),
    CarLeftAt:
        json['CarLeftAt'] == null ? null : DateTime.parse(json['CarLeftAt']),
    EvidencePhotos: evidencePhotosList,
  );
}

Map<String, dynamic> _$VehicleInformationToJson(VehicleInformation instance) {
  final evidencePhotosToJson =
      instance.EvidencePhotos!.map((model) => model.toJson()).toList();

  return <String, dynamic>{
    'Id': instance.Id ?? 0,
    'Created':
        instance.Created != null ? instance.Created!.toIso8601String() : null,
    'CreatedBy': instance.CreatedBy,
    'ExpiredAt': instance.ExpiredAt.toIso8601String(),
    'Plate': instance.Plate,
    'ZoneId': instance.ZoneId,
    'LocationId': instance.LocationId,
    'BayNumber': instance.BayNumber,
    'Type': instance.Type,
    'Latitude': instance.Latitude,
    'Longitude': instance.Longitude,
    'CarLeftAt': instance.CarLeftAt != null
        ? instance.CarLeftAt!.toIso8601String()
        : null,
    'EvidencePhotos': evidencePhotosToJson,
  };
}

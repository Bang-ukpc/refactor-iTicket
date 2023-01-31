enum TypePCN {
  Physical,
  Virtual,
}

class ContraventionCreateWardenCommand {
  String ContraventionReference;
  final String Plate;
  final String VehicleMake;
  final String VehicleColour;
  final String ContraventionReasonCode;
  final DateTime EventDateTime;
  final DateTime FirstObservedDateTime;
  final int WardenId;
  final String BadgeNumber;
  final num Longitude;
  final num Latitude;
  final int LocationAccuracy;
  final String WardenComments;
  final int? TypePCN;
  final int ZoneId;
  int? Id;

  ContraventionCreateWardenCommand({
    required this.ContraventionReference,
    required this.Plate,
    required this.VehicleMake,
    required this.VehicleColour,
    required this.ContraventionReasonCode,
    required this.EventDateTime,
    required this.FirstObservedDateTime,
    required this.WardenId,
    required this.BadgeNumber,
    required this.Longitude,
    required this.Latitude,
    required this.LocationAccuracy,
    required this.WardenComments,
    this.TypePCN,
    required this.ZoneId,
    this.Id,
  });

  factory ContraventionCreateWardenCommand.fromJson(
          Map<String, dynamic> json) =>
      _$ContraventionCreateWardenCommandFromJson(json);

  static Map<String, dynamic> toJson(
          ContraventionCreateWardenCommand instance) =>
      {
        'ContraventionReference': instance.ContraventionReference,
        'Plate': instance.Plate,
        'VehicleMake': instance.VehicleMake,
        'VehicleColour': instance.VehicleColour,
        'ContraventionReasonCode': instance.ContraventionReasonCode,
        'EventDateTime': instance.EventDateTime.toIso8601String(),
        'FirstObservedDateTime':
            instance.FirstObservedDateTime.toIso8601String(),
        'WardenId': instance.WardenId,
        'BadgeNumber': instance.BadgeNumber,
        'Longitude': instance.Longitude,
        'Latitude': instance.Latitude,
        'LocationAccuracy': instance.LocationAccuracy,
        'WardenComments': instance.WardenComments,
        'TypePCN': instance.TypePCN,
        'ZoneId': instance.ZoneId,
        'Id': instance.Id ?? 0,
      };
}

ContraventionCreateWardenCommand _$ContraventionCreateWardenCommandFromJson(
    Map<String, dynamic> json) {
  return ContraventionCreateWardenCommand(
    Id: json['Id'] ?? 0,
    ZoneId: json['ZoneId'],
    ContraventionReference: json['ContraventionReference'],
    Plate: json['Plate'],
    VehicleMake: json['VehicleMake'],
    VehicleColour: json['VehicleColour'],
    ContraventionReasonCode: json['ContraventionReasonCode'],
    EventDateTime: DateTime.parse(json['EventDateTime']),
    FirstObservedDateTime: DateTime.parse(json['FirstObservedDateTime']),
    WardenId: json['WardenId'],
    BadgeNumber: json['BadgeNumber'],
    Longitude: json['Longitude'],
    Latitude: json['Latitude'],
    LocationAccuracy: json['LocationAccuracy'],
    WardenComments: json['WardenComments'],
  );
}

class VehicleDetails {
  final String registrationNumber;
  final int co2Emissions;
  final int engineCapacity;
  final String euroStatus;
  final bool markedForExport;
  final String fuelType;
  final int revenueWeight;
  final String colour;
  final String make;
  final int yearOfManufacture;
  final String taxDueDate;
  final String taxStatus;
  final String dateOfLastV5CIssued;
  final String wheelplan;
  final String monthOfFirstDvlaRegistration;
  final String monthOfFirstRegistration;
  final String motStatus;
  final String motExpiryDate;

  VehicleDetails({
    required this.registrationNumber,
    required this.co2Emissions,
    required this.engineCapacity,
    required this.euroStatus,
    required this.markedForExport,
    required this.fuelType,
    required this.revenueWeight,
    required this.colour,
    required this.make,
    required this.yearOfManufacture,
    required this.taxDueDate,
    required this.taxStatus,
    required this.dateOfLastV5CIssued,
    required this.wheelplan,
    required this.monthOfFirstDvlaRegistration,
    required this.monthOfFirstRegistration,
    required this.motStatus,
    required this.motExpiryDate,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) =>
      _$VehicleDetailsFromJson(json);
}

VehicleDetails _$VehicleDetailsFromJson(Map<String, dynamic> json) {
  return VehicleDetails(
    registrationNumber: json['registrationNumber'],
    co2Emissions: json['co2Emissions'],
    engineCapacity: json['engineCapacity'],
    euroStatus: json['euroStatus'],
    markedForExport: json['markedForExport'],
    fuelType: json['fuelType'],
    revenueWeight: json['revenueWeight'],
    colour: json['colour'],
    make: json['make'],
    yearOfManufacture: json['yearOfManufacture'],
    taxDueDate: json['taxDueDate'],
    taxStatus: json['taxStatus'],
    dateOfLastV5CIssued: json['dateOfLastV5CIssued'],
    wheelplan: json['wheelplan'],
    monthOfFirstDvlaRegistration: json['monthOfFirstDvlaRegistration'],
    monthOfFirstRegistration: json['monthOfFirstRegistration'],
    motStatus: json['motStatus'],
    motExpiryDate: json['motExpiryDate'],
  );
}

class ContraventionCreatePhoto {
  final String contraventionReference;
  final int photoType;
  final String originalFileName;
  final DateTime capturedDateTime;
  final String filePath;

  ContraventionCreatePhoto({
    required this.contraventionReference,
    this.photoType = 5,
    required this.originalFileName,
    required this.capturedDateTime,
    required this.filePath,
  });

  factory ContraventionCreatePhoto.fromJson(Map<String, dynamic> json) =>
      _$ContraventionCreatePhotoFromJson(json);

  Map<String, dynamic> toJson() => _$ContraventionCreatePhotoToJson(this);
}

ContraventionCreatePhoto _$ContraventionCreatePhotoFromJson(
    Map<String, dynamic> json) {
  return ContraventionCreatePhoto(
    contraventionReference: json['contraventionReference'],
    photoType: json['photoType'],
    originalFileName: json['originalFileName'],
    capturedDateTime: DateTime.parse(json['capturedDateTime']),
    filePath: json['file'],
  );
}

Map<String, dynamic> _$ContraventionCreatePhotoToJson(
    ContraventionCreatePhoto instance) {
  return <String, dynamic>{
    'contraventionReference': instance.contraventionReference,
    'photoType': instance.photoType,
    'originalFileName': instance.originalFileName,
    'capturedDateTime': instance.capturedDateTime.toIso8601String(),
    'file': instance.filePath,
  };
}

class PermitInfo {
  final String? bayNumber;
  final String? source;
  final String? tenant;
  final String? VRN;

  PermitInfo({
    this.bayNumber,
    this.source,
    this.tenant,
    this.VRN,
  });

  factory PermitInfo.fromJson(Map<String, dynamic> json) => PermitInfo(
        VRN: json['VRN'],
        bayNumber: json['bayNumber'],
        source: json['source'],
        tenant: json['tenant'],
      );
}

class CheckPermit {
  final bool? hasPermit;
  final PermitInfo? permitInfo;

  CheckPermit({this.hasPermit, this.permitInfo});

  factory CheckPermit.fromJson(Map<String, dynamic> json) => CheckPermit(
        hasPermit: json['hasPermit'],
        permitInfo: PermitInfo.fromJson(
          json['permitInfo'],
        ),
      );
}

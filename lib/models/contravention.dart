class Contravention {
  DateTime? created;
  DateTime? deleted;
  int? id;
  int? locationId;
  int? activeAccountId;
  String? analysisKey;
  int? cancellationReasonId;
  String? colour;
  bool? isForeignPlate;
  int? locationRateId;
  int? lowerAmount;
  int? upperAmount;
  String? make;
  String? model;
  String? plate;
  int? reasonId;
  String? reference;
  int? status;
  int? type;
  int? zoneId;
  Reason? reason;
  DateTime? eventDateTime;
  List<ContraventionEvents>? contraventionEvents;
  List<ContraventionPhotos>? contraventionPhotos;
  ContraventionDetailsWarden? contraventionDetailsWarden;

  Contravention({
    this.created,
    this.deleted,
    this.id,
    this.locationId,
    this.activeAccountId,
    this.analysisKey,
    this.cancellationReasonId,
    this.colour,
    this.isForeignPlate,
    this.locationRateId,
    this.lowerAmount,
    this.upperAmount,
    this.make,
    this.model,
    this.plate,
    this.reasonId,
    this.reference,
    this.status,
    this.type,
    this.zoneId,
    this.reason,
    this.eventDateTime,
    this.contraventionEvents,
    this.contraventionPhotos,
    this.contraventionDetailsWarden,
  });

  Contravention.fromJson(Map<String, dynamic> json) {
    created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    deleted = json['Deleted'] == null ? null : DateTime.parse(json['Deleted']);
    id = json['Id'];
    locationId = json['LocationId'];
    activeAccountId = json['ActiveAccountId'];
    analysisKey = json['AnalysisKey'];
    cancellationReasonId = json['CancellationReasonId'];
    colour = json['Colour'];
    isForeignPlate = json['IsForeignPlate'];
    locationRateId = json['LocationRateId'];
    lowerAmount = json['LowerAmount'];
    upperAmount = json['UpperAmount'];
    make = json['Make'];
    model = json['Model'];
    plate = json['Plate'];
    reasonId = json['ReasonId'];
    reference = json['Reference'];
    status = json['Status'];
    type = json['Type'];
    zoneId = json['ZoneId'];
    reason = json['Reason'] != null ? Reason.fromJson(json['Reason']) : null;
    eventDateTime = json['EventDateTime'] == null
        ? null
        : DateTime.parse(json['EventDateTime']);
    if (json['ContraventionEvents'] != null) {
      contraventionEvents = <ContraventionEvents>[];
      json['ContraventionEvents'].forEach((v) {
        contraventionEvents!.add(ContraventionEvents.fromJson(v));
      });
    }
    if (json['ContraventionPhotos'] != null) {
      contraventionPhotos = <ContraventionPhotos>[];
      json['ContraventionPhotos'].forEach((v) {
        contraventionPhotos!.add(ContraventionPhotos.fromJson(v));
      });
    }
    contraventionDetailsWarden = json['ContraventionDetailsWarden'] != null
        ? ContraventionDetailsWarden.fromJson(
            json['ContraventionDetailsWarden'])
        : null;
  }

  static Map<String, dynamic> toJson(Contravention contravention) => {
        'Created': contravention.created != null
            ? contravention.created!.toIso8601String()
            : null,
        'Deleted': contravention.deleted != null
            ? contravention.deleted!.toIso8601String()
            : null,
        'EventDateTime': contravention.eventDateTime != null
            ? contravention.eventDateTime!.toIso8601String()
            : null,
        'Id': contravention.id,
        'LocationId': contravention.locationId,
        'ActiveAccountId': contravention.activeAccountId,
        'AnalysisKey': contravention.analysisKey,
        'CancellationReasonId': contravention.cancellationReasonId,
        'Colour': contravention.colour,
        'IsForeignPlate': contravention.isForeignPlate,
        'LocationRateId': contravention.locationRateId,
        'LowerAmount': contravention.lowerAmount,
        'UpperAmount': contravention.upperAmount,
        'Make': contravention.make,
        'Model': contravention.model,
        'Plate': contravention.plate,
        'ReasonId': contravention.reasonId,
        'Reference': contravention.reference,
        'Status': contravention.status,
        'Type': contravention.type,
        'ZoneId': contravention.zoneId,
        'Reason': contravention.reason != null
            ? contravention.reason!.toJson()
            : null,
        'ContraventionEvents': contravention.contraventionEvents != null
            ? contravention.contraventionEvents!.map((v) => v.toJson()).toList()
            : [],
        'ContraventionPhotos': contravention.contraventionPhotos != null
            ? contravention.contraventionPhotos!.isNotEmpty
                ? contravention.contraventionPhotos!
                    .map((v) => v.toJson())
                    .toList()
                : []
            : [],
      };
}

class Reason {
  DateTime? created;
  DateTime? deleted;
  int? id;
  String? code;
  int? rateTypeId;
  List<ContraventionReasonTranslations>? contraventionReasonTranslations;

  Reason({
    this.created,
    this.deleted,
    this.id,
    this.code,
    this.rateTypeId,
    this.contraventionReasonTranslations,
  });

  Reason.fromJson(Map<String, dynamic> json) {
    created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    deleted = json['Deleted'] == null ? null : DateTime.parse(json['Deleted']);
    id = json['Id'];
    code = json['Code'];
    rateTypeId = json['RateTypeId'];
    if (json['ContraventionReasonTranslations'] != null) {
      contraventionReasonTranslations = <ContraventionReasonTranslations>[];
      json['ContraventionReasonTranslations'].forEach((v) {
        contraventionReasonTranslations!
            .add(ContraventionReasonTranslations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Created'] = created != null ? created!.toIso8601String() : null;
    data['Deleted'] = deleted != null ? deleted!.toIso8601String() : null;
    data['Id'] = id;
    data['Code'] = code;
    data['RateTypeId'] = rateTypeId;
    if (contraventionReasonTranslations != null) {
      data['ContraventionReasonTranslations'] =
          contraventionReasonTranslations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ContraventionReasonTranslations {
  DateTime? created;
  DateTime? deleted;
  int? id;
  int? contraventionReasonId;
  String? summary;
  String? detail;
  Reason? contraventionReason;

  ContraventionReasonTranslations({
    this.created,
    this.deleted,
    this.id,
    this.contraventionReasonId,
    this.summary,
    this.detail,
    this.contraventionReason,
  });

  ContraventionReasonTranslations.fromJson(Map<String, dynamic> json) {
    created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    deleted = json['Deleted'] == null ? null : DateTime.parse(json['Deleted']);
    id = json['Id'];
    contraventionReasonId = json['ContraventionReasonId'];
    summary = json['Summary'];
    detail = json['Detail'];
    if (json['ContraventionReason'] != null) {
      contraventionReason = Reason.fromJson(json['ContraventionReason']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Created'] = created != null ? created!.toIso8601String() : null;
    data['Deleted'] = deleted != null ? deleted!.toIso8601String() : null;
    data['Id'] = id;
    data['ContraventionReasonId'] = contraventionReasonId;
    data['Summary'] = summary;
    data['Detail'] = detail;
    return data;
  }
}

class ContraventionEvents {
  DateTime? created;
  DateTime? deleted;
  int? id;
  Null? accountId;
  int? contraventionId;
  int? createdByUserId;
  String? detail;
  int? type;

  ContraventionEvents(
      {this.created,
      this.deleted,
      this.id,
      this.accountId,
      this.contraventionId,
      this.createdByUserId,
      this.detail,
      this.type});

  ContraventionEvents.fromJson(Map<String, dynamic> json) {
    created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    deleted = json['Deleted'] == null ? null : DateTime.parse(json['Deleted']);
    id = json['Id'];
    accountId = json['AccountId'];
    contraventionId = json['ContraventionId'];
    createdByUserId = json['CreatedByUserId'];
    detail = json['Detail'];
    type = json['Type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Created'] = created != null ? created!.toIso8601String() : null;
    data['Deleted'] = deleted != null ? deleted!.toIso8601String() : null;
    data['Id'] = id;
    data['AccountId'] = accountId;
    data['ContraventionId'] = contraventionId;
    data['CreatedByUserId'] = createdByUserId;
    data['Detail'] = detail;
    data['Type'] = type;
    return data;
  }
}

class ContraventionPhotos {
  DateTime? created;
  Null? deleted;
  int? id;
  String? capturedDateTime;
  int? contraventionId;
  int? photoType;
  String? blobName;
  String? mimeType;
  Null? modified;
  String? originalFilename;
  int? sizeInBytes;

  ContraventionPhotos(
      {this.created,
      this.deleted,
      this.id,
      this.capturedDateTime,
      this.contraventionId,
      this.photoType,
      this.blobName,
      this.mimeType,
      this.modified,
      this.originalFilename,
      this.sizeInBytes});

  ContraventionPhotos.fromJson(Map<String, dynamic> json) {
    created = json['Created'] == null ? null : DateTime.parse(json['Created']);
    deleted = json['Deleted'];
    id = json['Id'];
    capturedDateTime = json['CapturedDateTime'];
    contraventionId = json['ContraventionId'];
    photoType = json['PhotoType'];
    blobName = json['BlobName'];
    mimeType = json['MimeType'];
    modified = json['Modified'];
    originalFilename = json['OriginalFilename'];
    sizeInBytes = json['SizeInBytes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Created'] = created != null ? created!.toIso8601String() : null;
    data['Deleted'] = deleted;
    data['Id'] = id;
    data['CapturedDateTime'] = capturedDateTime;
    data['ContraventionId'] = contraventionId;
    data['PhotoType'] = photoType;
    data['BlobName'] = blobName;
    data['MimeType'] = mimeType;
    data['Modified'] = modified;
    data['OriginalFilename'] = originalFilename;
    data['SizeInBytes'] = sizeInBytes;
    return data;
  }
}

class ContraventionDetailsWarden {
  int? ContraventionId;
  int? WardenId;
  String? BadgeNumber;
  DateTime? FirstObserved;
  DateTime? IssuedAt;
  double? Longitude;
  double? Latitude;
  double? LocationAccuracy;

  ContraventionDetailsWarden({
    this.ContraventionId,
    this.WardenId,
    this.BadgeNumber,
    this.FirstObserved,
    this.IssuedAt,
    this.Longitude,
    this.Latitude,
    this.LocationAccuracy,
  });

  ContraventionDetailsWarden.fromJson(Map<String, dynamic> json) {
    ContraventionId = json['ContraventionId'];
    WardenId = json['WardenId'];
    BadgeNumber = json['BadgeNumber'];
    FirstObserved = json['FirstObserved'] == null
        ? null
        : DateTime.parse(json['FirstObserved']);
    IssuedAt =
        json['IssuedAt'] == null ? null : DateTime.parse(json['IssuedAt']);
    Latitude = json['Latitude'] == null ? 0 : json['Latitude'].toDouble();
    Longitude = json['Longitude'] == null ? 0 : json['Longitude'].toDouble();
    LocationAccuracy = json['LocationAccuracy'] == null
        ? 0
        : json['LocationAccuracy'].toDouble();
  }
}

enum ContraventionStatus {
  Open,
  Paid,
  Cancelled,
  Timeout,
  Paused,
}

import 'package:iWarden/models/base_model.dart';

class Service extends BaseModel {
  final int ZoneId;
  final int? ServiceType;
  final int? Status;
  final DateTime? InstallDate;
  final DateTime? TerminationDate;
  final String? Notes;
  final ServiceConfigModel ServiceConfig;

  Service({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    required this.ZoneId,
    this.ServiceType,
    this.Status,
    this.InstallDate,
    this.TerminationDate,
    this.Notes,
    required this.ServiceConfig,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => {
        'Id': Id,
        'Created': Created != null ? Created!.toIso8601String() : null,
        'Deleted': Deleted != null ? Deleted!.toIso8601String() : null,
        'ZoneId': ZoneId,
        'ServiceType': ServiceType,
        'Status': Status,
        'InstallDate':
            InstallDate != null ? InstallDate!.toIso8601String() : null,
        'TerminationDate':
            TerminationDate != null ? TerminationDate!.toIso8601String() : null,
        'Notes': Notes,
        'ServiceConfig': ServiceConfig.toJson(),
      };
}

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
      Id: json['Id'],
      Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
      Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
      ZoneId: json['ZoneId'],
      ServiceType: json['ServiceType'],
      Status: json['Status'],
      InstallDate: json['InstallDate'] == null
          ? null
          : DateTime.parse(json['InstallDate']),
      TerminationDate: json['TerminationDate'] == null
          ? null
          : DateTime.parse(json['TerminationDate']),
      Notes: json['Notes'],
      ServiceConfig: ServiceConfigModel.fromJson(json['ServiceConfig']),
    );

class ServiceConfigModel {
  final String? WardenNotes;
  final IssuePCNTypeModel IssuePCNType;
  final int FirstSeenPeriod;
  final int GracePeriod;

  ServiceConfigModel({
    this.WardenNotes,
    required this.IssuePCNType,
    required this.FirstSeenPeriod,
    required this.GracePeriod,
  });

  factory ServiceConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceConfigModelFromJson(json);

  Map<String, dynamic> toJson() => {
        'WardenNotes': WardenNotes,
        'IssuePCNType': IssuePCNType.toJson(),
        'FirstSeenPeriod': FirstSeenPeriod,
        'GracePeriod': GracePeriod,
      };
}

ServiceConfigModel _$ServiceConfigModelFromJson(Map<String, dynamic> json) {
  return ServiceConfigModel(
    WardenNotes: json['WardenNotes'],
    IssuePCNType: IssuePCNTypeModel.fromJson(
      json['IssuePCNType'],
    ),
    FirstSeenPeriod: json['FirstSeenPeriod'],
    GracePeriod: json['GracePeriod'],
  );
}

class IssuePCNTypeModel {
  final bool Physical;
  final bool Virtual;

  IssuePCNTypeModel({required this.Physical, required this.Virtual});

  factory IssuePCNTypeModel.fromJson(Map<String, dynamic> json) =>
      _$IssuePCNTypeModelFromJson(json);

  Map<String, dynamic> toJson() => {
        'Physical': Physical,
        'Virtual': Virtual,
      };
}

IssuePCNTypeModel _$IssuePCNTypeModelFromJson(Map<String, dynamic> json) =>
    IssuePCNTypeModel(
      Physical: json['Physical'],
      Virtual: json['Virtual'],
    );

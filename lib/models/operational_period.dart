import 'package:iWarden/models/base_model.dart';

class OperationalPeriodHistories extends BaseModel {
  final int RequireWarden;
  final DateTime TimeFrom;
  final DateTime TimeTo;
  final int LocationId;

  OperationalPeriodHistories({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    required this.RequireWarden,
    required this.TimeFrom,
    required this.TimeTo,
    required this.LocationId,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory OperationalPeriodHistories.fromJson(Map<String, dynamic> json) =>
      _$OperationalPeriodFromJson(json);

  static Map<String, dynamic> toJson(
          OperationalPeriodHistories operationalPeriod) =>
      {
        'Created': operationalPeriod.Created != null
            ? operationalPeriod.Created!.toIso8601String()
            : null,
        'Deleted': operationalPeriod.Deleted != null
            ? operationalPeriod.Deleted!.toIso8601String()
            : null,
        'Id': operationalPeriod.Id,
        'RequireWarden': operationalPeriod.RequireWarden,
        'TimeFrom': operationalPeriod.TimeFrom.toIso8601String(),
        'TimeTo': operationalPeriod.TimeTo.toIso8601String(),
        'LocationId': operationalPeriod.LocationId,
      };
}

OperationalPeriodHistories _$OperationalPeriodFromJson(
        Map<String, dynamic> json) =>
    OperationalPeriodHistories(
      Id: json['Id'],
      Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
      Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
      RequireWarden: json['RequireWarden'],
      TimeFrom: DateTime.parse(json['TimeFrom']),
      TimeTo: DateTime.parse(json['TimeTo']),
      LocationId: json['LocationId'],
    );

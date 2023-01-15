import 'package:iWarden/models/base_model.dart';

class OperationalPeriod extends BaseModel {
  final int Weekday;
  final int RequireWarden;
  final int TimeFrom;
  final int TimeTo;
  final int LocationId;

  OperationalPeriod({
    int? Id,
    DateTime? Created,
    DateTime? Deleted,
    required this.Weekday,
    required this.RequireWarden,
    required this.TimeFrom,
    required this.TimeTo,
    required this.LocationId,
  }) : super(Id: Id, Created: Created, Deleted: Deleted);

  factory OperationalPeriod.fromJson(Map<String, dynamic> json) =>
      _$OperationalPeriodFromJson(json);

  static Map<String, dynamic> toJson(OperationalPeriod operationalPeriod) => {
        'Created': operationalPeriod.Created != null
            ? operationalPeriod.Created!.toIso8601String()
            : null,
        'Deleted': operationalPeriod.Deleted != null
            ? operationalPeriod.Deleted!.toIso8601String()
            : null,
        'Id': operationalPeriod.Id,
        'Weekday': operationalPeriod.Weekday,
        'RequireWarden': operationalPeriod.RequireWarden,
        'TimeFrom': operationalPeriod.TimeFrom,
        'TimeTo': operationalPeriod.TimeTo,
        'LocationId': operationalPeriod.LocationId,
      };
}

OperationalPeriod _$OperationalPeriodFromJson(Map<String, dynamic> json) =>
    OperationalPeriod(
      Id: json['Id'],
      Created: json['Created'] == null ? null : DateTime.parse(json['Created']),
      Deleted: json['Deleted'] == null ? null : DateTime.parse(json['Deleted']),
      Weekday: json['Weekday'],
      RequireWarden: json['RequireWarden'],
      TimeFrom: json['TimeFrom'],
      TimeTo: json['TimeTo'],
      LocationId: json['LocationId'],
    );

class StatisticWardenPropsFilter {
  final int zoneId;
  final DateTime timeStart;
  final DateTime timeEnd;
  final int WardenId;
  StatisticWardenPropsFilter({
    required this.zoneId,
    required this.timeEnd,
    required this.timeStart,
    required this.WardenId,
  });
}

class StatisticWardenPropsData {
  final int abortedPCN;
  final int firstSeen;
  final int gracePeriod;
  final int issuedPCN;

  StatisticWardenPropsData({
    required this.abortedPCN,
    required this.firstSeen,
    required this.gracePeriod,
    required this.issuedPCN,
  });

  factory StatisticWardenPropsData.fromJson(Map<String, dynamic> json) =>
      statisticFromJson(json);

  Map<String, dynamic> toJson() => {
        'AbortedPCN': abortedPCN,
        'FirstSeen': firstSeen,
        'GracePeriod': gracePeriod,
        'IssuedPCN': issuedPCN,
      };
}

StatisticWardenPropsData statisticFromJson(Map<String, dynamic> json) {
  return StatisticWardenPropsData(
    abortedPCN: json['AbortedPCN'] ?? 0,
    firstSeen: json['FirstSeen'] ?? 0,
    gracePeriod: json['GracePeriod'] ?? 0,
    issuedPCN: json['IssuedPCN'] ?? 0,
  );
}

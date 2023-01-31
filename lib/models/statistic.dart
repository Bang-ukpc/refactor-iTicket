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

  static Map<String, dynamic> toJson(
          StatisticWardenPropsData statisticWardenPropsData) =>
      {
        'AbortedPCN': statisticWardenPropsData.abortedPCN,
        'FirstSeen': statisticWardenPropsData.firstSeen,
        'GracePeriod': statisticWardenPropsData.gracePeriod,
        'IssuedPCN': statisticWardenPropsData.issuedPCN,
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

import 'package:iWarden/models/base_model.dart';

enum LogLevel { debug, info, warn, error }

class BaseLog extends BaseModel {
  late LogLevel level;
  late String message;
  late String? detailMessage;

  Map<String, dynamic> toJson() => {
        'message': message,
        'detailMessage': detailMessage,
      };
}

class SyncLog extends BaseLog {
  SyncLog();
  SyncLog.simple(String message, [String? detailMessage]) {
    Created = DateTime.now();
    level = LogLevel.info;
    this.message = message;
    this.detailMessage = detailMessage;
  }
}

import 'dart:developer';

import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEventDataLocal");

  @override
  sync(WardenEvent wardenEvent) async {
    print("sync warden event");
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

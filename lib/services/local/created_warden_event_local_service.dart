import 'dart:developer';

import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/created_warden_event_local_background_service%20.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEventDataLocal");
  // @override
  // syncAll() async {
  //   if (isSyncing) {
  //     print("CreatedWardenEventLocalService is syncing");
  //     return;
  //   }
  //   isSyncing = true;
  //   List<WardenEvent> wardenEventsLocal = await getAll();

  //   wardenEventsLocal.sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
  //   for (var wardenEventItem in wardenEventsLocal) {
  //     await sync(wardenEventItem);
  //   }
  //   isSyncing = false;
  //   return super.syncAll();
  // }

  @override
  sync(WardenEvent wardenEvent) async {
    print("sync warden event");
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

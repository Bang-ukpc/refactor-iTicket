import 'dart:convert';
import 'dart:developer';

import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/created_warden_event_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalBackgroundService
    extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalBackgroundService()
      : super("wardenEventCheckGPSDataLocal");
  @override
  syncAll() async {
    if (isSyncing) {
      print("CreatedWardenEventLocalBackgroundService is syncing");
      return;
    }
    isSyncing = true;
    List<WardenEvent> wardenEventsBackgroundGPS = await getAll();
    List<WardenEvent> wardenEventsLocal =
        await createdWardenEventLocalService.getAll();
    createdWardenEventLocalService.deleteAll();
    List<WardenEvent> allWardenEvents = wardenEventsLocal
      ..addAll(wardenEventsBackgroundGPS);
    List<WardenEvent> allWardenEventsSort = allWardenEvents
      ..sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
    set(allWardenEventsSort);
    print('[allWardenEvents LENGTH] ${allWardenEvents.length}');

    for (int i = 0; i < allWardenEventsSort.length; i++) {
      log("[LOOP] ${i}");
      await sync(allWardenEventsSort[i]);
    }
    isSyncing = false;
    // return super.syncAll();
  }

  @override
  sync(WardenEvent wardenEvent) async {
    print('[async] ${json.encode(wardenEvent)}');
    try {
      WardenEvent clonedObject =
          WardenEvent.fromJson(json.decode(json.encode(wardenEvent)));
      clonedObject.Id = null;
      await userController.createWardenEvent(clonedObject);
    } catch (e) {
      print('[ERR] ${e.toString()}');
    } finally {
      print('[finally] ${json.encode(wardenEvent.Id)}');
      await delete(wardenEvent.Id ?? 0);
    }
  }
}

final createdWardenEventLocalBackgroundService =
    CreatedWardenEventLocalBackgroundService();

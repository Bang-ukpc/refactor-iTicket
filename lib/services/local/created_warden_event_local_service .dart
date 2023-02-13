import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEvents");
  @override
  syncAll() async {
    if (isSyncing) {
      print("CreatedWardenEventLocalService is syncing");
      return;
    }
    isSyncing = true;
    List<WardenEvent> events = await getAll();
    List<WardenEvent> sortedEvents = events
      ..sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
    print('[SYNC WARDEN EVENT] syncing ${events.length} events ...');

    for (int i = 0; i < sortedEvents.length; i++) {
      await sync(sortedEvents[i]);
    }
    isSyncing = false;
  }

  @override
  sync(WardenEvent wardenEvent) async {
    var eventId = wardenEvent.Id;
    try {
      wardenEvent.Id = null;
      await userController.createWardenEvent(wardenEvent);
      await delete(eventId ?? 0);
    } catch (e) {
      print('[SYNC WARDEN EVENT] error eventId.');
    }
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEvents");

  @override
  create(WardenEvent t) async {
    t.Created ??= DateTime.now();
    print(
        '[WARDEN EVENT] creating the event with type ${TypeWardenEvent.values[t.type].name}');
    await super.create(t);
    var events = await getAll();
    print(
        '[WARDEN EVENT] created the event with type ${TypeWardenEvent.values[t.type].name}. Total event ${events.length}');
  }

  @override
  syncAll() async {
    if (isSyncing) {
      print("[WARDEN EVENT] sync all event");
      // return;
    }
    isSyncing = true;
    List<WardenEvent> events = await getAll();
    print('[WARDEN EVENT] syncing ${events.length} events ...');
    List<WardenEvent> sortedEvents = events
      ..sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
    for (int i = 0; i < sortedEvents.length; i++) {
      await sync(sortedEvents[i]);
    }
    isSyncing = false;
  }

  @override
  sync(WardenEvent wardenEvent) async {
    var eventId = int.tryParse(wardenEvent.Id.toString());

    try {
      wardenEvent.Id = null;
      print(
          '[WARDEN EVENT] syncing event ${TypeWardenEvent.values[wardenEvent.type].name} created at ${wardenEvent.Created}');
      await userController.createWardenEvent(wardenEvent);
      await delete(eventId ?? 0);
    } catch (e) {
      print('[WARDEN EVENT] error eventId. ${e.toString()}');
      print('[WARDEN EVENT] ${e}');
    }
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

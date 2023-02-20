import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/local_service.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEvents");
  Logger logger = Logger<CreatedWardenEventLocalService>();

  @override
  create(WardenEvent t) async {
    t.Created ??= DateTime.now();
    logger.info(
        'creating event with type ${TypeWardenEvent.values[t.type].name}');
    await super.create(t);
  }

  @override
  syncAll() async {
    logger.info("Start syncing all the events ...");
    if (isSyncing) {
      logger.info("Sync process is running => IGNORE");
      return;
    }
    isSyncing = true;
    List<WardenEvent> events = await getAll();
    logger.info('syncing ${events.length} events ...');
    List<WardenEvent> sortedEvents = events
      ..sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
    for (var event in sortedEvents) {
      await sync(event);
    }
    isSyncing = false;
  }

  @override
  sync(WardenEvent wardenEvent) async {
    var eventId = int.tryParse(wardenEvent.Id.toString());

    try {
      wardenEvent.Id = null;
      logger.info(
          'Syncing event ${TypeWardenEvent.values[wardenEvent.type].name} created at ${wardenEvent.Created}');
      await userController.createWardenEvent(wardenEvent);
      await delete(eventId ?? 0);
    } catch (e) {
      logger.info('sync error ${e.toString()}');
    }
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

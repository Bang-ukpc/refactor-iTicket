import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../models/log.dart';

class CreatedWardenEventLocalService extends BaseLocalService<WardenEvent> {
  CreatedWardenEventLocalService() : super("wardenEvents");
  Logger logger = Logger<CreatedWardenEventLocalService>();

  @override
  create(WardenEvent t) async {
    DateTime now = await timeNTP.get();
    t.Created ??= now;
    logger.info(
        'creating event with type ${TypeWardenEvent.values[t.type].name}');
    await super.create(t);
  }

  @override
  syncAll(Function(bool isStop)? onStopSync,
      [Function(int current, int total, [SyncLog? log])?
          syncStatusCallBack]) async {
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
    if (syncStatusCallBack != null) syncStatusCallBack(0, sortedEvents.length);
    var amountSynced = 0;
    for (var event in sortedEvents) {
      if (onStopSync != null) {
        if (onStopSync(true) == true) break;
      }
      if (syncStatusCallBack != null) {
        syncStatusCallBack(amountSynced, sortedEvents.length);
      }
      try {
        await sync(event);
        amountSynced++;
        if (syncStatusCallBack != null) {
          syncStatusCallBack(amountSynced, sortedEvents.length);
        }
      } catch (e) {
        logger.info('sync error ${e.toString()}');
        if (syncStatusCallBack != null) {
          syncStatusCallBack(amountSynced, sortedEvents.length);
        }
      }
      if (syncStatusCallBack != null) {
        syncStatusCallBack(amountSynced, sortedEvents.length);
      }
    }
    isSyncing = false;
  }

  @override
  sync(WardenEvent wardenEvent) async {
    var eventId = int.tryParse(wardenEvent.Id.toString());
    wardenEvent.Id = null;
    logger.info(
        'Syncing event ${TypeWardenEvent.values[wardenEvent.type].name} created at ${wardenEvent.Created}');
    await userController.createWardenEvent(wardenEvent);
    await delete(eventId ?? 0);
  }
}

final createdWardenEventLocalService = CreatedWardenEventLocalService();

import 'package:iWarden/factory/sync_log_factory.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/cache/contravention_cached_service.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../controllers/contravention_controller.dart';
import '../../models/ContraventionService.dart';
import '../../models/log.dart';

class IssuedPcnLocalService
    extends BaseLocalService<ContraventionCreateWardenCommand> {
  late List<ContraventionCreatePhoto> allPcnPhotos;
  Logger logger = Logger<IssuedPcnLocalService>();

  IssuedPcnLocalService() : super('contraventions');

  @override
  create(ContraventionCreateWardenCommand t) {
    return super.create(t);
  }

  @override
  syncAll(
      [bool? isStopSyncing,
      Function(int current, int total, [SyncLog? log])?
          syncStatusCallBack]) async {
    logger.info("start syncing all ....");

    if (isSyncing) {
      logger.info("ignore because the process is syncing!");
      return;
    }
    isSyncing = true;
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    if (syncStatusCallBack != null) syncStatusCallBack(0, allPcns.length);
    logger.info("start syncing ${allPcns.length} items ....");
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();
    var amountSynced = 0;
    for (int i = 0; i < allPcns.length; i++) {
      if (isStopSyncing != null && isStopSyncing) break;
      var pcn = allPcns[i];
      if (syncStatusCallBack != null) {
        syncStatusCallBack(
            amountSynced, allPcns.length, syncLogFactory.logPCNSyncing(pcn));
      }
      try {
        await sync(pcn);
        amountSynced++;

        if (syncStatusCallBack != null) {
          syncStatusCallBack(
              amountSynced, allPcns.length, syncLogFactory.logPCNSynced(pcn));
        }
      } catch (e) {
        logger.error(e.toString());
        if (syncStatusCallBack != null) {
          syncStatusCallBack(amountSynced, allPcns.length,
              syncLogFactory.logPCNSyncFail(pcn, e.toString()));
        }
      }
    }
    await issuedPcnPhotoLocalService.syncAll(false);
    isSyncing = false;
  }

  @override
  sync(ContraventionCreateWardenCommand pcn) async {
    logger.info("syncing ${pcn.Plate} created at ${pcn.EventDateTime}");
    var contraventionCachedService = ContraventionCachedService(pcn.ZoneId);
    var cachedContravention = await contraventionCachedService
        .convertIssuesContraventionToCachedContravention(pcn);

    logger.info("sync continue");

    // sync to server
    await contraventionController.createPCN(pcn);
    await syncPcnPhotos(pcn);

    // create cached after sync
    // cachedContravention.created = now;
    await contraventionCachedService.create(cachedContravention);
    await delete(pcn.Id!);
  }

  syncPcnPhotos(ContraventionCreateWardenCommand pcn) async {
    var pcnPhotos = allPcnPhotos
        .where((photo) =>
            photo.contraventionReference == pcn.ContraventionReference)
        .toList();

    for (var pcnPhoto in pcnPhotos) {
      await issuedPcnPhotoLocalService.sync(pcnPhoto);
    }
  }
}

final issuedPcnLocalService = IssuedPcnLocalService();

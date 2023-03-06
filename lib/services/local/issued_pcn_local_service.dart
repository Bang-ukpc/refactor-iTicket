import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/services/cache/contravention_cached_service.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/contravention_controller.dart';
import '../../models/ContraventionService.dart';

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
  syncAll([Function(int current, int total)? statusFunc]) async {
    logger.info("start syncing all ....");

    if (isSyncing) {
      logger.info("ignore because the process is syncing!");
      return;
    }
    isSyncing = true;
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    if (statusFunc != null) statusFunc(0, allPcns.length);
    logger.info("start syncing ${allPcns.length} items ....");
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();
    var amountSynced = 0;
    for (int i = 0; i < allPcns.length; i++) {
      var pcn = allPcns[i];
      try {
        await sync(pcn);
        amountSynced++;
      } catch (e) {
        logger.error("syncing ${pcn.Plate} error ${e.toString()}");
      }
      if (statusFunc != null) statusFunc(amountSynced, allPcns.length);
    }
    await issuedPcnPhotoLocalService.syncAll();
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

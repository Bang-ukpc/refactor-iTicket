import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/cache/contravention_cached_service.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/contravention_controller.dart';
import '../../models/ContraventionService.dart';

class IssuedPcnLocalService
    extends BaseLocalService<ContraventionCreateWardenCommand> {
  late List<ContraventionCreatePhoto> allPcnPhotos;
  Logger logger = Logger();

  IssuedPcnLocalService() : super('contraventions');

  @override
  create(ContraventionCreateWardenCommand t) {
    return super.create(t);
  }

  @override
  syncAll() async {
    logger.info("start syncing all ....");

    if (isSyncing) {
      logger.info("ignore because the process is syncing!");
      return;
    }
    isSyncing = true;
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    logger.info("start syncing ${allPcns.length} items ....");
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();
    for (var pcn in allPcns) {
      await sync(pcn);
    }
    await issuedPcnPhotoLocalService.syncAll();
    isSyncing = false;
  }

  @override
  sync(ContraventionCreateWardenCommand pcn) async {
    logger.info("syncing ${pcn.Plate} created at ${pcn.EventDateTime}");
    try {
      var contraventionCachedService = ContraventionCachedService(pcn.ZoneId);
      var cachedContravention = await contraventionCachedService
          .convertIssuesContraventionToCachedContravention(pcn);

      // sync to server
      await contraventionController.createPCN(pcn);
      await syncPcnPhotos(pcn);

      // create cached after sync
      await contraventionCachedService.create(cachedContravention);
      await delete(pcn.Id!);
    } catch (e) {
      logger.error("syncing ${pcn.Plate} error ${e.toString()}");
    }
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

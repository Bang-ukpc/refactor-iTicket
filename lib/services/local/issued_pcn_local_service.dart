import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/contravention_controller.dart';
import '../../models/ContraventionService.dart';

class IssuedPcnLocalService
    extends BaseLocalService<ContraventionCreateWardenCommand> {
  late List<ContraventionCreatePhoto> allPcnPhotos;
  IssuedPcnLocalService(): super('issuePCNDataLocal');

  @override
  syncAll() async {
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();

    for (var pcn in allPcns) {
      await sync(pcn);
    }

    // Some photos can be missed to sync the server. So after sync all the PCNs we should sync the remaining photo.
    await issuedPcnPhotoLocalService.syncAll();
  }

  @override
  sync(ContraventionCreateWardenCommand pcn) async {
    Future.delayed(const Duration(seconds: 1), () async {
      await contraventionController.createPCN(pcn);
      await syncPcnPhotos(pcn);
      delete(pcn.Id!); // Prints after 1 second.
    });
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

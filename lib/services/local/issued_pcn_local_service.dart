import 'dart:convert';
import 'dart:math';

import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/contravention_controller.dart';
import '../../models/ContraventionService.dart';

class IssuedPcnLocalService
    extends BaseLocalService<ContraventionCreateWardenCommand> {
  late List<ContraventionCreatePhoto> allPcnPhotos;

  IssuedPcnLocalService() : super('contraventions');

  @override
  create(ContraventionCreateWardenCommand t) {
    return super.create(t);
  }

  @override
  syncAll() async {
    if (isSyncing) {
      print("IssuedPcnLocalService is syncing");
      return;
    }
    isSyncing = true;
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();
    for (var pcn in allPcns) {
      await sync(pcn);
    }
    await issuedPcnPhotoLocalService.syncAll();
    isSyncing = false;
  }

  @override
  sync(ContraventionCreateWardenCommand pcn) async {
    print("syn!!!!!!");
    try {
      await contraventionController.createPCN(pcn);
      await syncPcnPhotos(pcn);
    } catch (e) {
      print(e.toString());
    } finally {
      await delete(pcn.Id!);
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

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
  bool isSyncing = false;

  IssuedPcnLocalService() : super('issuePCNDataLocal');

  @override
  syncAll() async {
    // if (isSyncing) {
    //   print("IssuedPcnLocalService is syncing");
    //   return;
    // }

    isSyncing = true;
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    allPcnPhotos = await issuedPcnPhotoLocalService.getAll();

    for (int i = 0; i < allPcns.length; i++) {
      await sync(allPcns[i]);
    }

    // Some photos can be missed to sync the server. So after sync all the PCNs we should sync the remaining photo.
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

  delete2(int id) async {
    print("id pcn $id");
    List<ContraventionCreateWardenCommand> allPcns = await getAll();
    final updatedItems = allPcns.where((element) => element.Id != id);
    SharedPreferencesHelper.setStringValue(
        'issuePCNDataLocal', json.encode(updatedItems));
  }
}

final issuedPcnLocalService = IssuedPcnLocalService();

import 'dart:convert';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../controllers/contravention_controller.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/ContraventionService.dart';

class IssuedPcnLocalService
    extends ILocalService<ContraventionCreateWardenCommand> {
  late List<ContraventionCreatePhoto> allPcnPhotos;
  final String LOCAL_KEY = 'issuePCNDataLocal';

  @override
  create(ContraventionCreateWardenCommand pcn) {}

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
    await contraventionController.createPCN(pcn);
    await syncPcnPhotos(pcn);
    delete(pcn);
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

  @override
  getAll() async {
    final String? jsonPcns =
        await SharedPreferencesHelper.getStringValue(LOCAL_KEY);
    var decodedData = json.decode(jsonPcns!) as List<dynamic>;
    var allPcns = decodedData
        .map((e) => ContraventionCreateWardenCommand.fromJson(json.decode(e)))
        .toList();
    return allPcns;
  }

  @override
  delete(ContraventionCreateWardenCommand pcn) {}
}

final issuedPcnLocalService = IssuedPcnLocalService();

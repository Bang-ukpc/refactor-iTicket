import 'dart:convert';
import '../../controllers/contravention_controller.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/ContraventionService.dart';

const PCN_KEY = 'issuePCNDataLocal';
const PCN_PHOTO_KEY = 'contraventionPhotoDataLocal';

class IssuedPcnLocalService {
  createPcn() {
    //TODO: Save PCN to share reference
  }
  
  syncAllPcns() async {
    List<ContraventionCreateWardenCommand> allPcns = await getAllPcns();
    List<ContraventionCreatePhoto> allPcnPhotos = await getAllPcnPhotos();

    for(var pcn in allPcns){
      var pcnPhotos = allPcnPhotos.where((photo) => photo.contraventionReference == pcn.ContraventionReference).toList();
      await syncPcn(pcn, pcnPhotos);
    }
  }

  syncPcn(ContraventionCreateWardenCommand pcn, List<ContraventionCreatePhoto> pcnPhotos) async {
    // TODO: what happen when the user kill the app and the PCN already synced but the photos still not.
    await contraventionController.createPCN(pcn);
    removePcnOnTheLocalList(pcn.ContraventionReference);

    for (var pcnPhoto in pcnPhotos) {
      await syncPcnPhoto(pcnPhoto);
    }
  }

  syncPcnPhoto(ContraventionCreatePhoto pcnPhoto) async {
    await contraventionController.uploadContraventionImage(pcnPhoto);
    removePcnPhotoOnTheLocalList(pcnPhoto.contraventionReference);
  }

  getAllPcns() async {
    final String? jsonPcns =
        await SharedPreferencesHelper.getStringValue(PCN_KEY);
    var decodedData = json.decode(jsonPcns!) as List<dynamic>;
    var allPcns = decodedData
        .map((e) => ContraventionCreateWardenCommand.fromJson(json.decode(e)))
        .toList();
    return allPcns;
  }

  getAllPcnPhotos() async {
    final String? jsonPcnPhotos =
        await SharedPreferencesHelper.getStringValue(PCN_PHOTO_KEY);
    var decodedData = json.decode(jsonPcnPhotos!) as List<dynamic>;
    var allPcnPhotos = decodedData
        .map((e) => ContraventionCreatePhoto.fromJson(json.decode(e)))
        .toList();
    return allPcnPhotos;
  }

  removePcnOnTheLocalList(String pcnReference){
    print('[LOCAL] Remove PCN $pcnReference');
  }

  removePcnPhotoOnTheLocalList(String pcnPhotoId){
    print('[LOCAL] Remove PCN Photo $pcnPhotoId');
  }
}

final issuedPcnLocalService = IssuedPcnLocalService();
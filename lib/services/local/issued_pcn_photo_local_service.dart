import 'dart:convert';

import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../controllers/contravention_controller.dart';
import '../../helpers/shared_preferences_helper.dart';

class IssuedPcnPhotoLocalService
    extends ILocalService<ContraventionCreatePhoto> {
  final String LOCAL_KEY = 'contraventionPhotoDataLocal';

  @override
  create(ContraventionCreatePhoto pcnPhoto) {}

  @override
  syncAll() async {
   List<ContraventionCreatePhoto> allPcnPhotos = await getAll();

    for (var pcnPhoto in allPcnPhotos) {
      await sync(pcnPhoto);
    }
  }

  @override
  sync(ContraventionCreatePhoto pcnPhoto) async {
    await contraventionController.uploadContraventionImage(pcnPhoto);
    await delete(pcnPhoto);
  }

  @override
  getAll() async {
    final String? jsonPcnPhotos =
        await SharedPreferencesHelper.getStringValue(LOCAL_KEY);
    var decodedData = json.decode(jsonPcnPhotos!) as List<dynamic>;
    var allPcnPhotos = decodedData
        .map((e) => ContraventionCreatePhoto.fromJson(json.decode(e)))
        .toList();
    return allPcnPhotos;
  }

  @override
  delete(ContraventionCreatePhoto pcnPhoto) {}
}

final issuedPcnPhotoLocalService = IssuedPcnPhotoLocalService();

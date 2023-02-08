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
    if (jsonPcnPhotos != null) {
      var decodedData = json.decode(jsonPcnPhotos) as List<dynamic>;
      var allPcnPhotos = decodedData
          .map((e) => ContraventionCreatePhoto.fromJson(json.decode(e)))
          .toList();
      return allPcnPhotos;
    }
  }

  @override
  delete(ContraventionCreatePhoto pcnPhoto) async {
    List<ContraventionCreatePhoto> allPcnPhotos = await getAll();
    List<ContraventionCreatePhoto> _allPcnPhotos = allPcnPhotos
        .where((element) => element.filePath != pcnPhoto.filePath)
        .toList();
    final encodedNewData = json.encode(_allPcnPhotos);
    SharedPreferencesHelper.setStringValue(LOCAL_KEY, encodedNewData);
  }
}

final issuedPcnPhotoLocalService = IssuedPcnPhotoLocalService();

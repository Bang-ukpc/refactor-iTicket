import 'dart:convert';
import 'dart:developer';

import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../controllers/contravention_controller.dart';

class IssuedPcnPhotoLocalService
    extends BaseLocalService<ContraventionCreatePhoto> {
  IssuedPcnPhotoLocalService() : super('contraventionPhotos');

  Future<List<ContraventionCreatePhoto>> listByContraventionReference(
      String contraventionReference) async {
    List<ContraventionCreatePhoto> photos = await getAll();
    log('[CONTRAVENTION CREATE PHOTOS] ${json.encode(photos)}');
    var selectedPhotos = photos
        .where(
            (photo) => photo.contraventionReference == contraventionReference)
        .toList();
    log('[CONTRAVENTION PHOTOS] ${json.encode(selectedPhotos)}');
    return selectedPhotos;
  }

  ContraventionPhotos toContraventionPhoto(ContraventionCreatePhoto photo) {
    return ContraventionPhotos(
        blobName: photo.filePath, contraventionId: photo.Id);
  }

  @override
  syncAll([Function(int current, int total)? statusFunc]) async {
    List<ContraventionCreatePhoto> allPcnPhotos = await getAll();
    for (var pcnPhoto in allPcnPhotos) {
      await sync(pcnPhoto);
    }
  }

  @override
  sync(ContraventionCreatePhoto pcnPhoto) async {
    try {
      await contraventionController.uploadContraventionImage(pcnPhoto);
      await delete(pcnPhoto.Id!);
    } catch (e) {
      print(e.toString());
    }
  }
}

final issuedPcnPhotoLocalService = IssuedPcnPhotoLocalService();

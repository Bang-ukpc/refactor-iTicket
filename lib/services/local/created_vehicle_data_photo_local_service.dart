import 'dart:convert';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/evidence_photo_controller.dart';
import '../../helpers/logger.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataPhotoLocalService
    extends BaseLocalService<EvidencePhoto> {
  CreatedVehicleDataPhotoLocalService() : super("vehiclePhotos");
  Logger logger = Logger<CreatedVehicleDataPhotoLocalService>();

  @override
  Future<EvidencePhoto?> sync(EvidencePhoto evidencePhoto) async {
    logger.info('syncing ${evidencePhoto.Id} to sever ... ');
    var uploadedEvidentPhoto = await evidencePhotoController
        .uploadImage(
            filePath: evidencePhoto.BlobName,
            capturedDateTime: evidencePhoto.Created)
        .then((value) async {
      evidencePhoto.BlobName = value['blobName'];
      return EvidencePhoto(BlobName: evidencePhoto.BlobName);
    });
    await delete(evidencePhoto.Id!);
    return uploadedEvidentPhoto;
  }

  @override
  bulkCreate(List<EvidencePhoto> listT) {
    logger.info(
        '[VEHICLE INFO] [EVIDENT PHOTO] bulk create with ${listT.length} items');
    return super.bulkCreate(listT);
  }

  @override
  Future<List<EvidencePhoto>> getAll() async {
    final items = await super.getAll();
    logger.info('[VEHICLE INFO] [EVIDENT PHOTO] get all ${json.encode(items)}');
    return items;
  }
}

final createdVehicleDataPhotoLocalService =
    CreatedVehicleDataPhotoLocalService();

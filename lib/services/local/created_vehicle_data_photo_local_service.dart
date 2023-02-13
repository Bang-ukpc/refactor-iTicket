import 'dart:convert';

import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/evidence_photo_controller.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataPhotoLocalService
    extends BaseLocalService<EvidencePhoto> {
  CreatedVehicleDataPhotoLocalService() : super("vehiclePhotos");

  @override
  Future<EvidencePhoto?> sync(EvidencePhoto evidencePhoto) async {
    print('[EVIDENCE PHOTO] syncing ${evidencePhoto.Id} to sever ... ');
    try {
      return evidencePhotoController
          .uploadImage(
              filePath: evidencePhoto.BlobName,
              capturedDateTime: evidencePhoto.Created)
          .then((value) async {
        print("[THEN] ${json.encode(value)}");
        if (value['blobName'] != null) {
          evidencePhoto.BlobName = value['blobName'];
          await delete(evidencePhoto.Id!);

          return EvidencePhoto(BlobName: evidencePhoto.BlobName);
        } else {
          print("NULL $value");
        }
      });
    } catch (e) {
      print("err ${e.toString()}");
      print('[catch]${evidencePhoto.BlobName}');
      return EvidencePhoto(BlobName: evidencePhoto.BlobName);
    } finally {
      print('[finally] ${evidencePhoto.BlobName}');
      // return EvidencePhoto(BlobName: evidencePhoto.BlobName);
    }
  }

  @override
  bulkCreate(List<EvidencePhoto> listT) {
    print(
        '[VEHICLE INFO] [EVIDENT PHOTO] bulk create with ${listT.length} items');
    return super.bulkCreate(listT);
  }

  @override
  Future<List<EvidencePhoto>> getAll() async {
    final items = await super.getAll();
    print('[VEHICLE INFO] [EVIDENT PHOTO] get all ${json.encode(items)}');
    return items;
  }
}

final createdVehicleDataPhotoLocalService =
    CreatedVehicleDataPhotoLocalService();

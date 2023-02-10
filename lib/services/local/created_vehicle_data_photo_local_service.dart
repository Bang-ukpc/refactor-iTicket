import 'dart:convert';

import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/evidence_photo_controller.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataPhotoLocalService
    extends BaseLocalService<EvidencePhoto> {
  CreatedVehicleDataPhotoLocalService() : super("vehicleInfoUpsertDataLocal");

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
}

final createdVehicleDataPhotoLocalService =
    CreatedVehicleDataPhotoLocalService();

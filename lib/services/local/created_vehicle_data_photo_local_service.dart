import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/evidence_photo_controller.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataPhotoLocalService
    extends BaseLocalService<EvidencePhoto> {
  CreatedVehicleDataPhotoLocalService() : super("vehicleInfoUpsertDataLocal");

  @override
  sync(EvidencePhoto evidencePhoto) async {
    try {
      return evidencePhotoController
          .uploadImage(
              filePath: evidencePhoto.BlobName,
              capturedDateTime: evidencePhoto.Created)
          .then((value) {
        evidencePhoto.BlobName = value['blobName'];
        return evidencePhoto;
      });
    } catch (e) {
      print(e.toString());
      return evidencePhoto;
    } finally {
      await delete(evidencePhoto.Id!);
      return evidencePhoto;
    }
  }
}

final createdVehicleDataPhotoLocalService =
    CreatedVehicleDataPhotoLocalService();

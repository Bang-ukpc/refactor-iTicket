import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/evidence_photo_controller.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataPhotoLocalService
    extends BaseLocalService<EvidencePhoto> {
  CreatedVehicleDataPhotoLocalService() : super("vehicleInfoUpsertDataLocal");

  @override
  sync(EvidencePhoto evidencePhoto) async {
    try {
      evidencePhotoController.uploadImage(
          filePath: evidencePhoto.BlobName,
          capturedDateTime: evidencePhoto.Created);
    } catch (e) {
      print(e.toString());
    } finally {
      await delete(evidencePhoto.Id!);
    }
  }
//  Future <EvidencePhoto> syncPhoto(EvidencePhoto evidencePhoto) async {
//     try {
//       evidencePhotoController.uploadImage(
//           filePath: evidencePhoto.BlobName,
//           capturedDateTime: evidencePhoto.Created).then((value) => value);
//     } catch (e) {
//       print(e.toString());
//     } finally {
//       await delete(evidencePhoto.Id!);
//     }
}

final createdVehicleDataPhotoLocalService =
    CreatedVehicleDataPhotoLocalService();

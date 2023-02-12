import 'dart:convert';
import 'dart:math';

import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/services/local/created_vehicle_data_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataLocalService
    extends BaseLocalService<VehicleInformation> {
  CreatedVehicleDataLocalService() : super("vehicleInfoUpsertDataLocal");

  @override
  create(VehicleInformation t) async {
    for (var photo in (t.EvidencePhotos ?? [])) {
      await createdVehicleDataPhotoLocalService.create(photo);
    }
    return super.create(t);
  }

  @override
  sync(VehicleInformation vehicleInformation) async {
    try {
      syncPcnPhotos(vehicleInformation.EvidencePhotos!).then((value) {
        vehicleInformation.EvidencePhotos = value;
        print("[syncPcnPhotos] value ${json.encode(vehicleInformation)}");
        if (vehicleInformation.Id != null && vehicleInformation.Id! < 0) {
          vehicleInformation.Id = null;
        }
        vehicleInfoController.upsertVehicleInfo(vehicleInformation);
      });
    } catch (e) {
      print(e.toString());
    } finally {
      await delete(vehicleInformation.Id!);
    }
  }

  Future<List<VehicleInformation>> getAllFirstSeen() async {
    var items = await getAll();
    return items
        .where((element) =>
            element.Type == VehicleInformationType.FIRST_SEEN.index)
        .toList();
  }

  Future<List<VehicleInformation>> getAllGracePeriod() async {
    var items = await getAll();
    return items
        .where((element) =>
            element.Type == VehicleInformationType.GRACE_PERIOD.index)
        .toList();
  }

  Future<List<EvidencePhoto>> syncPcnPhotos(
      List<EvidencePhoto> evidencePhoto) async {
    List<EvidencePhoto> allVehiclePhotos = [];
    for (var evidencePhoto in evidencePhoto) {
      evidencePhoto.Created = evidencePhoto.Created;
      print('[UPLOAD] EvidencePhoto');
      EvidencePhoto? uploadedEvidencePhoto =
          await createdVehicleDataPhotoLocalService.sync(evidencePhoto);
      if (uploadedEvidencePhoto != null) {
        allVehiclePhotos.add(uploadedEvidencePhoto);
      }
    }
    print("[length] allVehiclePhotos ${allVehiclePhotos.length}");
    return allVehiclePhotos;
  }
}

final createdVehicleDataLocalService = CreatedVehicleDataLocalService();

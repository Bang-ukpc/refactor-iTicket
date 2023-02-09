import 'dart:convert';

import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/services/local/created_vehicle_data_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/vehicle_information.dart';

class CreatedVehicleDataLocalService
    extends BaseLocalService<VehicleInformation> {
  CreatedVehicleDataLocalService() : super("vehicleInfoUpsertDataLocal");
  late List<EvidencePhoto> allVehiclePhotos;
  @override
  sync(VehicleInformation vehicleInformation) async {
    try {
      for (var evidencePhoto in vehicleInformation.EvidencePhotos!) {
        evidencePhoto.Created = vehicleInformation.Created;
        EvidencePhoto data = createdVehicleDataPhotoLocalService
            .sync(evidencePhoto) as EvidencePhoto;
        allVehiclePhotos.add(data);
      }
      vehicleInformation.EvidencePhotos = allVehiclePhotos;
      await vehicleInfoController.upsertVehicleInfo(vehicleInformation);
    } catch (e) {
      print(e.toString());
    } finally {
      await delete(vehicleInformation.Id!);
    }
  }

  syncPhoto() {}
}

final createdVehicleDataLocalService = CreatedVehicleDataLocalService();

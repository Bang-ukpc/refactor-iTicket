import 'dart:convert';

import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/services/cache/cache_service.dart';
import 'package:iWarden/services/cache/first_seen_cached_service.dart';
import 'package:iWarden/services/cache/grace_period_cached_service.dart';
import 'package:iWarden/services/local/created_vehicle_data_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../models/vehicle_information.dart';

class CreatedVehicleDataLocalService
    extends BaseLocalService<VehicleInformation> {
  CreatedVehicleDataLocalService() : super("vehicles");

  @override
  create(VehicleInformation t) async {
    print(
        '[VEHICLE INFO] creating ${t.Plate} with ${t.EvidencePhotos?.length} photos ...');
    if (t.EvidencePhotos!.isNotEmpty) {
      await createdVehicleDataPhotoLocalService
          .bulkCreate(t.EvidencePhotos as List<EvidencePhoto>);
    }
    return super.create(t);
  }

  @override
  syncAll() async {
    print('[VEHICLE INFO] syncing all ...');

    if (isSyncing) {
      print("[VEHICLE INFO] CreatedVehicleDataLocalService is syncing ...");
      return;
    }
    isSyncing = true;

    final items = await getAll();
    print('[VEHICLE INFO SYNC ALL] ${items.map((e) => e.Id)}');
    for (var item in items) {
      await sync(item);
    }

    isSyncing = false;
  }

  @override
  Future<List<VehicleInformation>> getAll() async {
    final items = await super.getAll();
    print('[VEHICLE INFO] get all ${json.encode(items)}');
    return items;
  }

  @override
  sync(VehicleInformation vehicleInformation) async {
    print(
        '[VEHICLE INFO] syncing ${vehicleInformation.Plate} with ${vehicleInformation.EvidencePhotos?.length} images ...');
    try {
      await syncPcnPhotos(vehicleInformation.EvidencePhotos!).then((evidencePhotos) async {
        vehicleInformation.EvidencePhotos = evidencePhotos;
        if (vehicleInformation.Id != null && vehicleInformation.Id! < 0) {
          vehicleInformation.Id = null;
        }
        await vehicleInfoController.upsertVehicleInfo(vehicleInformation);
        await createCachedVehicleInformationAfterSync(vehicleInformation);
      });
    } catch (e) {
      print(e.toString());
    } finally {
      await delete(vehicleInformation.Id!);
    }
  }

  createCachedVehicleInformationAfterSync(VehicleInformation vehicle) async {
    if (vehicle.Type == VehicleInformationType.FIRST_SEEN.index) {
      ICacheService<VehicleInformation> cachedService =
          vehicle.Type == VehicleInformationType.FIRST_SEEN.index
              ? FirstSeenCachedService(vehicle.ZoneId)
              : GracePeriodCachedService(vehicle.ZoneId);
      await cachedService.create(vehicle);
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

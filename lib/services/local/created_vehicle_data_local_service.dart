import 'dart:convert';

import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/id_helper.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/cache/cache_service.dart';
import 'package:iWarden/services/cache/first_seen_cached_service.dart';
import 'package:iWarden/services/cache/grace_period_cached_service.dart';
import 'package:iWarden/services/local/created_vehicle_data_photo_local_service.dart';
import 'package:iWarden/services/local/local_service.dart';

import '../../models/vehicle_information.dart';

class CreatedVehicleDataLocalService
    extends BaseLocalService<VehicleInformation> {
  Logger logger = Logger<CreatedVehicleDataLocalService>();
  CreatedVehicleDataLocalService() : super("vehicles");

  @override
  create(VehicleInformation t) async {
    logger.info(
        'creating ${t.Plate} with ${t.EvidencePhotos?.length} photos ...');
    if (t.EvidencePhotos!.isNotEmpty) {
      await createdVehicleDataPhotoLocalService
          .bulkCreate(t.EvidencePhotos as List<EvidencePhoto>);
    }
    var existedItem = await get(t.Id!);
    return existedItem != null ? update(t) : super.create(t);
  }

  @override
  syncAll() async {
    logger.info('syncing all ...');

    if (isSyncing) {
      logger.info("CreatedVehicleDataLocalService is syncing ...");
      return;
    }
    isSyncing = true;

    final items = await getAll();
    logger.info('${items.map((e) => e.Id)}');
    for (var item in items) {
      await sync(item);
    }

    isSyncing = false;
  }

  @override
  Future<List<VehicleInformation>> getAll() async {
    final items = await super.getAll();
    logger.info('get all ${json.encode(items)}');
    return items;
  }

  @override
  sync(VehicleInformation vehicleInformation) async {
    logger.info(
        'syncing ${vehicleInformation.Plate} with ${vehicleInformation.EvidencePhotos?.length} images ...');
    var vehicleId = vehicleInformation.Id != null
        ? int.tryParse(vehicleInformation.Id.toString())
        : null;
    bool isNewItem = idHelper.isGeneratedByLocal(vehicleInformation.Id);
    logger.info("syncing isNewItem $isNewItem");
    try {
      await syncPcnPhotos(vehicleInformation.EvidencePhotos!)
          .then((evidencePhotos) async {
        vehicleInformation.EvidencePhotos = evidencePhotos;
        if (isNewItem) {
          vehicleInformation.Id = null;
        }
        await vehicleInfoController.upsertVehicleInfo(vehicleInformation);

        if (isNewItem) {
          await createCachedVehicleInformationAfterSync(vehicleInformation);
        }
        await delete(vehicleId ?? 0);
      });
    } catch (e) {
      logger.info(e.toString());
    } finally {}
  }

  createCachedVehicleInformationAfterSync(VehicleInformation vehicle) async {
    ICacheService<VehicleInformation> cachedService =
        vehicle.Type == VehicleInformationType.FIRST_SEEN.index
            ? FirstSeenCachedService(vehicle.ZoneId)
            : GracePeriodCachedService(vehicle.ZoneId);
    await cachedService.create(vehicle);
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
      logger.info('[UPLOAD] EvidencePhoto');
      EvidencePhoto? uploadedEvidencePhoto =
          await createdVehicleDataPhotoLocalService.sync(evidencePhoto);
      if (uploadedEvidencePhoto != null) {
        allVehiclePhotos.add(uploadedEvidencePhoto);
      }
    }
    logger.info("[length] allVehiclePhotos ${allVehiclePhotos.length}");
    return allVehiclePhotos;
  }
}

final createdVehicleDataLocalService = CreatedVehicleDataLocalService();

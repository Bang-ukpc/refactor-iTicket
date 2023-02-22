import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/id_helper.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/cache/cache_service.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
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
      logger.info("the process to sync is running => IGNORE");
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
    try {
      await syncPcnPhotos(vehicleInformation.EvidencePhotos!)
          .then((evidencePhotos) async {
        vehicleInformation.EvidencePhotos = evidencePhotos;
        if (isNewItem) {
          vehicleInformation.Id = null;
        }
        if (vehicleInformation.Id != null) {
          var latestItem = await get(vehicleInformation.Id!);
          if (latestItem != null && latestItem.CarLeftAt != null) {
            vehicleInformation.CarLeftAt = latestItem.CarLeftAt!;
          }
        }
        await vehicleInfoController.upsertVehicleInfo(vehicleInformation);

        if (isNewItem) {
          await createCachedVehicleInformationAfterSync(vehicleInformation);
        }
        await delete(vehicleId ?? 0);
      });
    } catch (e) {
      logger.info(e.toString());
    }
    return null;
  }

  createCachedVehicleInformationAfterSync(VehicleInformation vehicle) async {
    ICacheService<VehicleInformation> cachedService =
        vehicle.Type == VehicleInformationType.FIRST_SEEN.index
            ? FirstSeenCachedService(vehicle.ZoneId)
            : GracePeriodCachedService(vehicle.ZoneId);
    await cachedService.create(vehicle);
  }

  Future<List<VehicleInformation>> getAllFirstSeen(int zoneId) async {
    var items = await getAll();
    return items
        .where((element) =>
            element.ZoneId == zoneId &&
            element.Type == VehicleInformationType.FIRST_SEEN.index)
        .toList();
  }

  Future<List<VehicleInformation>> getAllGracePeriod(int zoneId) async {
    var items = await getAll();
    return items
        .where((element) =>
            element.ZoneId == zoneId &&
            element.Type == VehicleInformationType.GRACE_PERIOD.index)
        .toList();
  }

  Future<List<EvidencePhoto>> syncPcnPhotos(
    List<EvidencePhoto> evidencePhotos,
  ) async {
    List<EvidencePhoto> allVehiclePhotos = [];
    logger.info('[UPLOAD] ${evidencePhotos.length} evident photos');
    for (var evidencePhoto in evidencePhotos) {
      evidencePhoto.Created = evidencePhoto.Created;
      EvidencePhoto? uploadedEvidencePhoto =
          await createdVehicleDataPhotoLocalService.sync(evidencePhoto);
      if (uploadedEvidencePhoto != null) {
        allVehiclePhotos.add(uploadedEvidencePhoto);
      }
    }
    logger.info("[length] allVehiclePhotos ${allVehiclePhotos.length}");
    return allVehiclePhotos;
  }

  onCarLeft(VehicleInformation vehicleInfo) async {
    vehicleInfo.CarLeftAt = DateTime.now().add(const Duration(seconds: 3));
    // cerate sync to server
    if (await get(vehicleInfo.Id!) == null) {
      await create(vehicleInfo);
    } else {
      await update(vehicleInfo);
    }

    //delete from cache
    var zoneCachedServiceFactory = ZoneCachedServiceFactory(vehicleInfo.ZoneId);
    if (vehicleInfo.Type == VehicleInformationType.FIRST_SEEN.index) {
      await zoneCachedServiceFactory.firstSeenCachedService
          .delete(vehicleInfo.Id!);
    } else {
      await zoneCachedServiceFactory.gracePeriodCachedService
          .delete(vehicleInfo.Id!);
    }

    var items = await getAll();
    logger.info('items ${items.map((e) => e.Id)}');
  }
}

final createdVehicleDataLocalService = CreatedVehicleDataLocalService();

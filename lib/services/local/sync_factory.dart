import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/services/local/issued_pcn_local_service.dart';

import '../../helpers/logger.dart';

class SyncFactory {
  bool isRunning = false;
  late CreatedVehicleDataLocalService createdVehicleDataLocalService;
  late IssuedPcnLocalService issuedPcnLocalService;
  late CreatedWardenEventLocalService createdWardenEventLocalService;
  Logger logger = Logger<SyncFactory>();

  SyncFactory() {
    createdVehicleDataLocalService = CreatedVehicleDataLocalService();
    issuedPcnLocalService = IssuedPcnLocalService();
    createdWardenEventLocalService = CreatedWardenEventLocalService();
  }
  syncToServer() async {
    logger.info('Starting ...');
    if (isRunning) {
      logger.info('The process is running => IGNORE');
      return;
    }

    isRunning = true;
    try {
      await createdVehicleDataLocalService.syncAll();
      await issuedPcnLocalService.syncAll();
      await createdWardenEventLocalService.syncAll();
    } catch (e) {
      logger.error(e);
    }
    isRunning = false;
  }
}

final syncFactory = SyncFactory();

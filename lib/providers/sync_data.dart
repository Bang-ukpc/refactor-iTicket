import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:iWarden/helpers/check_background_service_status_helper.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/services/local/issued_pcn_local_service.dart';
import 'package:iWarden/services/local/sync_factory.dart';

class SyncData with ChangeNotifier {
  static Logger logger = Logger<SyncData>();
  Timer? timer;
  static int totalWardenEvent = 0;
  static int totalVehicleInfo = 0;
  static int totalPcn = 0;
  static bool isSyncingStatus = false;

  int get totalDataNeedToSync => totalWardenEvent + totalVehicleInfo + totalPcn;

  bool get isSyncing => isSyncingStatus;

  Future<void> getQuantity() async {
    totalWardenEvent = await createdWardenEventLocalService.total();
    totalVehicleInfo = await createdVehicleDataLocalService.total();
    totalPcn = await issuedPcnLocalService.total();
    notifyListeners();
  }

  Future<void> startSync(Function(bool isSyncingData)? setSyncStatus) async {
    if (setSyncStatus != null) {
      setSyncStatus(true);
    }
    isSyncingStatus = true;
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await getQuantity();
      bool isBackgroundRunning =
          await checkBackgroundServiceStatusHelper.isRunning();
      if (isBackgroundRunning) {
        logger.info('Stopping sync');
        if (setSyncStatus != null) {
          setSyncStatus(false);
        }
        stopSync();
      } else {
        if (totalDataNeedToSync > 0) {
          logger.info('Syncing to server');
          await syncFactory.syncToServer();
        } else {
          logger.info('Stopping sync');
          if (setSyncStatus != null) {
            setSyncStatus(false);
          }
          stopSync();
        }
      }
    });
    notifyListeners();
  }

  void stopSync() {
    isSyncingStatus = false;
    if (timer != null) {
      timer?.cancel();
    }
    logger.info('Stopped sync');
    notifyListeners();
  }
}

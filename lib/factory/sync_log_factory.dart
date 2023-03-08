import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/log.dart';
import 'package:iWarden/models/vehicle_information.dart';

class SyncLogFactory {
  logVehicleInformationSyncing(VehicleInformation vehicleInfo) {
    return SyncLog.simple(
        '[Syncing] [${_genVehicleInfoDisplayType(vehicleInfo.Type)}] ${vehicleInfo.Plate} ${vehicleInfo.Created}');
  }

  logVehicleInformationSynced(VehicleInformation vehicleInfo) {
    return SyncLog.simple(
        '[Synced] [${_genVehicleInfoDisplayType(vehicleInfo.Type)}] ${vehicleInfo.Plate} ${vehicleInfo.Created}');
  }

  logVehicleInformationSyncFail(VehicleInformation vehicleInfo, String error) {
    var syncLog = SyncLog();
    syncLog.level = LogLevel.error;
    syncLog.message =
        '[Sync failed] [${_genVehicleInfoDisplayType(vehicleInfo.Type)}] ${vehicleInfo.Plate} ${vehicleInfo.Created}';
    syncLog.detailMessage = error;
    return syncLog;
  }

  logPCNSyncing(ContraventionCreateWardenCommand pcn) {
    return SyncLog.simple(
        '[Syncing] [PCN] ${pcn.Plate} ${pcn.ContraventionReference} ${pcn.EventDateTime}');
  }

  logPCNSynced(ContraventionCreateWardenCommand pcn) {
    return SyncLog.simple(
        '[Synced] [PCN] ${pcn.Plate} ${pcn.ContraventionReference} ${pcn.EventDateTime}');
  }

  logPCNSyncFail(ContraventionCreateWardenCommand pcn, String error) {
    var syncLog = SyncLog();
    syncLog.level = LogLevel.error;
    syncLog.message =
        '[Syncing failed] [PCN] ${pcn.Plate} ${pcn.ContraventionReference} ${pcn.EventDateTime}';
    syncLog.detailMessage = error;
    return syncLog;
  }

  _genVehicleInfoDisplayType(int type) {
    return type == VehicleInformationType.FIRST_SEEN.index
        ? 'First seen'
        : 'Grace period';
  }
}

final syncLogFactory = SyncLogFactory();

import 'package:flutter/material.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/sync-data/syncing_request_screen.dart';

import '../../services/local/created_vehicle_data_local_service.dart';
import '../../services/local/issued_pcn_local_service.dart';

class CheckSyncDataLayout extends StatefulWidget {
  static const routeName = '/confirm-sync-data';
  const CheckSyncDataLayout({super.key});

  @override
  State<CheckSyncDataLayout> createState() => _CheckSyncDataLayoutState();
}

class _CheckSyncDataLayoutState extends State<CheckSyncDataLayout> {
  int totalVehicleInfoNeedToSync = 0;
  int totalPcnNeedToSync = 0;
  bool? isGetTotalSuccess;

  Future<void> getQuantityOfSyncData() async {
    int totalVehicleInfo = await createdVehicleDataLocalService.total();
    int totalPcn = await issuedPcnLocalService.total();
    setState(() {
      totalVehicleInfoNeedToSync = totalVehicleInfo;
      totalPcnNeedToSync = totalPcn;
      isGetTotalSuccess = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getQuantityOfSyncData();
  }

  @override
  Widget build(BuildContext context) {
    Widget getWidgetFirstValid() {
      if (isGetTotalSuccess != null) {
        if (totalVehicleInfoNeedToSync > 0 || totalPcnNeedToSync > 0) {
          return const SyncingRequestScreen();
        } else {
          return const ConnectingScreen();
        }
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return getWidgetFirstValid();
  }
}

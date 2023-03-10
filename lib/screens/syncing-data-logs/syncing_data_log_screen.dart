import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/models/log.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

import '../../services/local/created_vehicle_data_local_service.dart';
import '../../services/local/issued_pcn_local_service.dart';

class SyncingDataLogScreen extends StatefulWidget {
  static const routeName = '/syncing-data-log';
  const SyncingDataLogScreen({super.key});

  @override
  State<SyncingDataLogScreen> createState() => _SyncingDataLogScreenState();
}

class _SyncingDataLogScreenState extends State<SyncingDataLogScreen> {
  int totalDataNeedToSync = 0;
  int progressingDataNeedToSync = 0;
  bool isSyncing = false;
  List<SyncLog?> syncLogs = [];
  bool isStopSyncing = false;

  Future<void> getQuantityOfSyncData() async {
    int totalVehicleInfo = await createdVehicleDataLocalService.total();
    int totalPcn = await issuedPcnLocalService.total();
    setState(() {
      totalDataNeedToSync = totalVehicleInfo + totalPcn;
    });
  }

  Future<void> syncDataToServer() async {
    setState(() {
      isSyncing = true;
      syncLogs = [];
    });
    await createdVehicleDataLocalService.syncAll((isStop) => isStopSyncing,
        (current, total, [log]) {
      setState(() {
        progressingDataNeedToSync = current;
        syncLogs.add(log);
      });
    });

    await issuedPcnLocalService.syncAll((isStop) => isStopSyncing,
        (current, total, [log]) {
      setState(() {
        progressingDataNeedToSync =
            current + progressingDataNeedToSync >= totalDataNeedToSync
                ? totalDataNeedToSync
                : current + progressingDataNeedToSync;
        syncLogs.add(log);
      });
    });
    setState(() {
      isSyncing = false;
    });
  }

  void stopSyncing() {
    isStopSyncing = true;
    setState(() {
      isSyncing = false;
    });
  }

  Future<void> syncAgain() async {
    isStopSyncing = false;
    await getQuantityOfSyncData();
    await syncDataToServer();
  }

  @override
  void initState() {
    super.initState();
    getQuantityOfSyncData();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await syncDataToServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Syncing data logs',
                        style: CustomTextStyle.h4.copyWith(
                          color: ColorTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$progressingDataNeedToSync/$totalDataNeedToSync',
                        style: CustomTextStyle.h4.copyWith(
                          color: ColorTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: syncLogs.map((e) {
                      if (e != null && e.message.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.message,
                              style: CustomTextStyle.body1.copyWith(
                                color: e.level == LogLevel.info
                                    ? ColorTheme.textPrimary
                                    : ColorTheme.danger,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            if (e.detailMessage != null)
                              Column(
                                children: [
                                  Text(
                                    'Message: ${e.detailMessage}',
                                    style: CustomTextStyle.body1.copyWith(
                                      color: ColorTheme.danger,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                ],
                              )
                          ],
                        );
                      }
                      return const SizedBox();
                    }).toList(),
                  ),
                  if (!isSyncing)
                    Text(
                      "[Finish syncing]",
                      style: CustomTextStyle.body1.copyWith(
                        color: ColorTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isSyncing)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: SvgPicture.asset(
                      "assets/svg/IconStop.svg",
                      color: ColorTheme.textPrimary,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: ColorTheme.grey300,
                    ),
                    onPressed: () {
                      stopSyncing();
                    },
                    label: Text(
                      'Stop syncing',
                      style: CustomTextStyle.h5.copyWith(
                          color: ColorTheme.textPrimary, fontSize: 16),
                    ),
                  ),
                ),
              if (!isSyncing &&
                  totalDataNeedToSync > 0 &&
                  progressingDataNeedToSync != totalDataNeedToSync)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: SvgPicture.asset(
                      "assets/svg/IconRefresh2.svg",
                      color: ColorTheme.textPrimary,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: ColorTheme.grey300,
                    ),
                    onPressed: () async {
                      await syncAgain();
                    },
                    label: Text(
                      'Sync again',
                      style: CustomTextStyle.h5.copyWith(
                          color: ColorTheme.textPrimary, fontSize: 16),
                    ),
                  ),
                ),
              if (!isSyncing &&
                  totalDataNeedToSync > 0 &&
                  progressingDataNeedToSync != totalDataNeedToSync)
                const SizedBox(
                  width: 16,
                ),
              if (!isSyncing)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: SvgPicture.asset(
                      "assets/svg/IconComplete2.svg",
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(ConnectingScreen.routeName);
                    },
                    label: Text(
                      'Finish',
                      style: CustomTextStyle.h5
                          .copyWith(color: ColorTheme.white, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/syncing-data-logs/syncing_data_log_screen.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../../services/local/issued_pcn_local_service.dart';
import '../connecting-status/background_service_config.dart';

class SyncingRequestScreen extends StatefulWidget {
  static const routeName = '/syncing-request';
  const SyncingRequestScreen({super.key});

  @override
  State<SyncingRequestScreen> createState() => _SyncingRequestScreenState();
}

class _SyncingRequestScreenState extends State<SyncingRequestScreen> {
  int totalEventNeedToSync = 0;
  int totalVehicleInfoNeedToSync = 0;
  int totalPcnNeedToSync = 0;
  bool isGetTotalNeedToSyncLoading = false;

  void onStartBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      await initializeService();
    }
  }

  Future<void> getQuantityOfSyncData() async {
    setState(() {
      isGetTotalNeedToSyncLoading = true;
    });
    int totalWardenEvent = await createdWardenEventLocalService.total();
    int totalVehicleInfo = await createdVehicleDataLocalService.total();
    int totalPcn = await issuedPcnLocalService.total();
    setState(() {
      totalEventNeedToSync = totalWardenEvent;
      totalVehicleInfoNeedToSync = totalVehicleInfo;
      totalPcnNeedToSync = totalPcn;
      isGetTotalNeedToSyncLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    onStartBackgroundService();
    getQuantityOfSyncData();
  }

  @override
  Widget build(BuildContext context) {
    final syncData = Provider.of<SyncData>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        bottomNavigationBar: const VersionName(),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(
                  height: 60,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Syncing request ",
                        style: CustomTextStyle.h3
                            .copyWith(color: ColorTheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Some data has not been synced. \nDo you want to sync now?',
                        textAlign: TextAlign.center,
                        style: CustomTextStyle.body1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Details',
                            style: CustomTextStyle.body1
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      !isGetTotalNeedToSyncLoading
                          ? Column(
                              children: [
                                if (totalEventNeedToSync > 0)
                                  Column(
                                    children: [
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '1. Event',
                                            style: CustomTextStyle.body1,
                                          ),
                                          Text(
                                            '$totalEventNeedToSync',
                                            style: CustomTextStyle.body1,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (totalVehicleInfoNeedToSync > 0)
                                  Column(
                                    children: [
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${totalEventNeedToSync > 0 ? '2' : '1'}. First seen & Consideration period',
                                            style: CustomTextStyle.body1,
                                          ),
                                          Text(
                                            '$totalVehicleInfoNeedToSync',
                                            style: CustomTextStyle.body1,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (totalPcnNeedToSync > 0)
                                  Column(
                                    children: [
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${totalEventNeedToSync > 0 ? totalVehicleInfoNeedToSync > 0 ? '3' : '2' : '1'}. Parking Charge Notices (PCNs)',
                                            style: CustomTextStyle.body1,
                                          ),
                                          Text(
                                            '$totalPcnNeedToSync',
                                            style: CustomTextStyle.body1,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: SvgPicture.asset(
                            "assets/svg/IconSkip.svg",
                            color: ColorTheme.textPrimary,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: ColorTheme.grey300,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                ConnectingScreen.routeName,
                                (Route<dynamic> route) => false);
                          },
                          label: Text(
                            "Skip & next",
                            style: CustomTextStyle.h5.copyWith(
                                color: ColorTheme.textPrimary, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: SvgPicture.asset(
                            "assets/svg/IconSave.svg",
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            syncData.stopSync();
                            if (!mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                SyncingDataLogScreen.routeName,
                                (Route<dynamic> route) => false);
                          },
                          label: Text(
                            "Sync now",
                            style: CustomTextStyle.h5
                                .copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

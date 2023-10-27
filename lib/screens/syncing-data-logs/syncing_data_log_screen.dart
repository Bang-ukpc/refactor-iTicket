import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/helpers/check_turn_on_net_work.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/log.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/auth/login_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/info_drawer.dart';
import 'package:provider/provider.dart';

import '../../services/local/created_vehicle_data_local_service.dart';
import '../../services/local/created_warden_event_local_service .dart';
import '../../services/local/issued_pcn_local_service.dart';

class SyncingDataLogScreen extends StatefulWidget {
  static const routeName = '/syncing-data-log';
  const SyncingDataLogScreen({super.key});

  @override
  State<SyncingDataLogScreen> createState() => _SyncingDataLogScreenState();
}

class _SyncingDataLogScreenState extends State<SyncingDataLogScreen> {
  Logger logger = Logger<SyncingDataLogScreen>();
  int totalDataNeedToSync = 0;
  int progressingWardenEvent = 0;
  int progressingVehicleInfo = 0;
  int progressingPcns = 0;
  bool isSyncingWardenEvent = false;
  List<SyncLog?> syncLogs = [];
  bool isStopSyncing = false;
  bool isStoppingSyncing = false;
  bool isSyncing = false;
  final ScrollController _controller = ScrollController();
  int totalDataAll = 0;
  int totalEvent = 0;

  Future<void> getQuantityOfSyncData() async {
    int totalWardenEvent = await createdWardenEventLocalService.total();
    int totalVehicleInfo = await createdVehicleDataLocalService.total();
    int totalPcn = await issuedPcnLocalService.total();
    setState(() {
      totalDataNeedToSync = totalWardenEvent + totalVehicleInfo + totalPcn;
    });
  }

  Future<void> getTotalDataAll() async {
    int totalWardenEvent = await createdWardenEventLocalService.total();
    int totalVehicleInfo = await createdVehicleDataLocalService.total();
    int totalPcn = await issuedPcnLocalService.total();
    setState(() {
      totalDataAll = totalWardenEvent + totalVehicleInfo + totalPcn;
    });
  }

  Future syncData({int totalPreviousVehicleInfo = 0}) async {
    logger.info('Start sync data');
    await Future.wait([
      Future(() async {
        await createdWardenEventLocalService.syncAll(
          (isStop) => isStopSyncing,
          (current, total, [log]) {
            _controller.animateTo(_controller.position.maxScrollExtent,
                curve: Curves.fastOutSlowIn,
                duration: const Duration(seconds: 1));
            logger.info('[progressingWardenEvent] $current');
            setState(() {
              progressingWardenEvent = current;
              isStoppingSyncing = false;
            });
          },
        );

        int totalWardenEvent = await createdWardenEventLocalService.total();
        setState(() {
          totalEvent = totalWardenEvent;
          isSyncingWardenEvent = false;
        });
      }),
      Future(() async {
        await createdVehicleDataLocalService.syncAll((isStop) => isStopSyncing,
            (current, total, [log]) {
          _controller.animateTo(_controller.position.maxScrollExtent,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(seconds: 1));
          logger.info('[progressingVehicleInfo] $current');
          setState(() {
            progressingVehicleInfo = totalPreviousVehicleInfo + current;
            isStoppingSyncing = false;
            syncLogs.add(log);
          });
        });

        int totalVehicleInfo = await createdVehicleDataLocalService.total();
        if (totalVehicleInfo > 0 &&
            !isStopSyncing &&
            await checkTurnOnNetWork.turnOnWifiAndMobile()) {
          logger.info('Sync Vehicle info data is not complete');
          await syncData(totalPreviousVehicleInfo: progressingVehicleInfo);
          return;
        }

        await issuedPcnLocalService.syncAll((isStop) => isStopSyncing,
            (current, total, [log]) {
          _controller.animateTo(_controller.position.maxScrollExtent,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(seconds: 1));
          logger.info('[progressingPcns] $current');
          setState(() {
            progressingPcns = current;
            isStoppingSyncing = false;
            syncLogs.add(log);
          });
        });
      }),
    ]);
  }

  Future<void> startSyncToServer() async {
    logger.info('Start sync to server');
    setState(() {
      isSyncing = true;
      isSyncingWardenEvent = true;
      syncLogs = [];
    });

    await syncData();

    _controller.animateTo(_controller.position.maxScrollExtent,
        curve: Curves.fastOutSlowIn, duration: const Duration(seconds: 1));

    await getTotalDataAll();

    setState(() {
      isSyncing = false;
    });
  }

  void stopSyncing() {
    isStopSyncing = true;
    setState(() {
      isStoppingSyncing = true;
    });
  }

  Future<void> syncAgain() async {
    isStopSyncing = false;
    await getQuantityOfSyncData();
    await getTotalDataAll();
    await startSyncToServer();
  }

  void onPauseBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
  }

  @override
  void initState() {
    super.initState();
    onPauseBackgroundService();
    getQuantityOfSyncData();
    getTotalDataAll();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await startSyncToServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final args = ModalRoute.of(context)!.settings.arguments as dynamic;
    int action = args != null ? args['action'] : -1;

    Future userLogOut() async {
      await auth.logout().then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamedAndRemoveUntil(
            LoginScreen.routeName, (Route<dynamic> route) => false);
        CherryToast.success(
          displayCloseButton: false,
          title: Text(
            'Log out successfully',
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      });
    }

    Widget getButtonByEvent() {
      if (action == EventAction.logout.index) {
        if (totalDataAll <= 0) {
          return Expanded(
            child: ElevatedButton.icon(
              icon: SvgPicture.asset(
                "assets/svg/IconEndShift.svg",
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                if (!mounted) return;
                showCircularProgressIndicator(
                    context: context, text: "Logging out");
                await userLogOut();
              },
              label: Text(
                'Logout',
                style: CustomTextStyle.h5
                    .copyWith(color: ColorTheme.white, fontSize: 16),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      } else {
        return Expanded(
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
        );
      }
    }

    Widget textDataEventSyncStatus(String text) => Column(
          children: [
            Text(
              text,
              style: CustomTextStyle.body1.copyWith(
                color: ColorTheme.textPrimary,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
          ],
        );

    logger.info(
        'is syncing: $isSyncing, totalDataNeedToSync: $totalDataAll, total progress: ${progressingWardenEvent + progressingVehicleInfo + progressingPcns} in there: progressingWardenEvent: $progressingWardenEvent, progressingVehicleInfo: $progressingVehicleInfo, progressingPcns: $progressingPcns');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: ColorTheme.textPrimary,
            statusBarIconBrightness: Brightness.light,
          ),
          elevation: 5,
          shadowColor: ColorTheme.boxShadow3,
          title: Row(
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
                '${progressingWardenEvent + progressingVehicleInfo + progressingPcns}/$totalDataNeedToSync',
                style: CustomTextStyle.h4.copyWith(
                  color: ColorTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _controller,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSyncingWardenEvent)
                    textDataEventSyncStatus(
                        'Synchronizing event data with the server...'),
                  if (!isSyncingWardenEvent && totalEvent > 0)
                    textDataEventSyncStatus(
                        'Data event synchronization with the unfinished server'),
                  if (!isSyncingWardenEvent && totalEvent <= 0)
                    textDataEventSyncStatus(
                        'Synchronize data events with the completed server'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 62 + 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
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
                        onPressed: !isStoppingSyncing
                            ? () {
                                stopSyncing();
                              }
                            : null,
                        label: Text(
                          isStoppingSyncing
                              ? 'Stopping syncing...'
                              : 'Stop syncing',
                          style: CustomTextStyle.h5.copyWith(
                              color: ColorTheme.textPrimary, fontSize: 16),
                        ),
                      ),
                    ),
                  if (!isSyncing &&
                      totalDataAll > 0 &&
                      (progressingWardenEvent +
                              progressingVehicleInfo +
                              progressingPcns) !=
                          totalDataNeedToSync)
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
                      totalDataAll > 0 &&
                      (progressingWardenEvent +
                              progressingVehicleInfo +
                              progressingPcns) !=
                          totalDataNeedToSync &&
                      action != EventAction.logout.index)
                    const SizedBox(
                      width: 16,
                    ),
                  if (!isSyncing) getButtonByEvent(),
                ],
              ),
              const VersionName(),
              const SizedBox(
                height: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

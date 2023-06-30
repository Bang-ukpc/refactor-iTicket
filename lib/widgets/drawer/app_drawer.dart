import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/bluetooth_printer.dart';
import 'package:iWarden/helpers/check_background_service_status_helper.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/start-break-screen/start_break_screen.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/display_alert.dart';
import 'package:iWarden/widgets/drawer/model/data.dart';
import 'package:iWarden/widgets/drawer/model/menu_item.dart';
import 'package:iWarden/widgets/drawer/model/nav_item.dart';
import 'package:iWarden/widgets/drawer/nav_item.dart';
import 'package:iWarden/widgets/drawer/spot_check.dart';
import 'package:iWarden/widgets/layouts/check_sync_data_layout.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/local/created_warden_event_local_service .dart';
import '../../theme/color.dart';
import 'info_drawer.dart';
import 'item_menu_widget.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool? checkBluetooth;
  final _debouncer = Debouncer(milliseconds: 3000);
  final _debouncer2 = Debouncer(milliseconds: 4000);
  Stream<BluetoothState> bluetoothStateStream =
      FlutterBluePlus.instance.state.asBroadcastStream();
  bool isSyncingData = false;

  void onConnectPrinter() {
    bluetoothPrinterHelper.scan();
    bluetoothPrinterHelper.initConnect();
  }

  // Check bluetooth connection
  void _checkDeviceBluetoothIsOn() async {
    var check = await FlutterBluePlus.instance.isOn;
    setState(() {
      checkBluetooth = check;
    });
  }

  void onCheckIsSyncing(bool isSyncing) {
    setState(() {
      isSyncingData = isSyncing;
    });
  }

  @override
  void initState() {
    super.initState();
    bluetoothStateStream.listen((bluetoothState) {
      _checkDeviceBluetoothIsOn();
    });
    _checkDeviceBluetoothIsOn();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final syncData = Provider.of<SyncData>(context, listen: false);
      await syncData.getQuantity();
      onCheckIsSyncing(syncData.isSyncing);
    });
  }

  @override
  void dispose() {
    bluetoothPrinterHelper.disposePrinter();
    if (_debouncer.timer != null) {
      _debouncer.timer!.cancel();
    }
    if (_debouncer2.timer != null) {
      _debouncer2.timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widthScreen = MediaQuery.of(context).size.width;
    final wardensProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);
    final syncData = Provider.of<SyncData>(context);

    WardenEvent wardenEventStartBreak = WardenEvent(
      type: TypeWardenEvent.StartBreak.index,
      detail: 'Warden has begun to rest',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    WardenEvent wardenEventCheckOut = WardenEvent(
      type: TypeWardenEvent.CheckOut.index,
      detail: 'Warden checked out',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    WardenEvent wardenEventEndShift = WardenEvent(
      type: TypeWardenEvent.EndShift.index,
      detail: 'Warden has ended shift',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    void onStartBreak() async {
      try {
        showCircularProgressIndicator(context: context);
        await createdWardenEventLocalService
            .create(wardenEventStartBreak)
            .then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(StartBreakScreen.routeName);
        });
      } on DioError catch (error) {
        if (error.type == DioErrorType.other) {
          Navigator.of(context).pop();
          CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              error.message.length > Constant.errorTypeOther
                  ? 'Something went wrong, please try again'
                  : error.message,
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        Navigator.of(context).pop();
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

    void onEndShift(Auth auth) async {
      try {
        showCircularProgressIndicator(context: context);
        final service = FlutterBackgroundService();
        service.invoke("endShiftService");
        await createdWardenEventLocalService
            .create(wardenEventCheckOut)
            .then((value) async {
          await createdWardenEventLocalService
              .create(wardenEventEndShift)
              .then((value) async {
            SharedPreferencesHelper.removeStringValue(
                PreferencesKeys.rotaShiftSelectedByWarden);
            SharedPreferencesHelper.removeStringValue(
                PreferencesKeys.locationSelectedByWarden);
            SharedPreferencesHelper.removeStringValue(
                PreferencesKeys.zoneSelectedByWarden);
            if (!mounted) return;
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
                CheckSyncDataLayout.routeName, (Route<dynamic> route) => false,
                arguments: 'check-out');
          });
        });
      } on DioError catch (error) {
        if (error.type == DioErrorType.other) {
          Navigator.of(context).pop();
          CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              error.message.length > Constant.errorTypeOther
                  ? 'Something went wrong, please try again'
                  : error.message,
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        Navigator.of(context).pop();
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

    List<Widget> getList() {
      return DataMenuItem()
          .data
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ItemMenuWidget(
                itemMenu: e,
                onTap: e.route == 'coming soon'
                    ? () {
                        Navigator.of(context).pop();
                        CherryToast.info(
                          displayCloseButton: false,
                          title: Text(
                            'Coming soon',
                            style: CustomTextStyle.h4
                                .copyWith(color: ColorTheme.secondary),
                          ),
                          toastPosition: Position.bottom,
                          borderRadius: 5,
                        ).show(context);
                      }
                    : e.route == 'testPrinter'
                        ? () async {
                            if (checkBluetooth == true) {
                              if (!bluetoothPrinterHelper.isConnected) {
                                onConnectPrinter();
                              }
                              if (!mounted) return;
                              if (bluetoothPrinterHelper.selectedPrinter ==
                                  null) {
                                showCircularProgressIndicator(
                                  context: context,
                                  text: 'Connecting to printer',
                                );
                                _debouncer.run(() {
                                  Navigator.of(context).pop();
                                  CherryToast.error(
                                    toastDuration: const Duration(seconds: 5),
                                    title: Text(
                                      "Can't connect to a printer. Enable Bluetooth on both mobile device and printer and check that devices are paired.",
                                      style: CustomTextStyle.h4
                                          .copyWith(color: ColorTheme.danger),
                                    ),
                                    toastPosition: Position.bottom,
                                    borderRadius: 5,
                                  ).show(context);
                                });
                                bluetoothPrinterHelper.subscriptionBtStatus!
                                    .cancel();
                              } else {
                                showCircularProgressIndicator(
                                    context: context,
                                    text: 'Connecting to printer');
                                await bluetoothPrinterHelper.printReceiveTest();
                                _debouncer2.run(() {
                                  if (bluetoothPrinterHelper.isConnected ==
                                      false) {
                                    Navigator.of(context).pop();
                                    CherryToast.error(
                                      toastDuration: const Duration(seconds: 5),
                                      title: Text(
                                        "Can't connect to a printer. Enable Bluetooth on both mobile device and printer and check that devices are paired.",
                                        style: CustomTextStyle.h4
                                            .copyWith(color: ColorTheme.danger),
                                      ),
                                      toastPosition: Position.bottom,
                                      borderRadius: 5,
                                    ).show(context);
                                    bluetoothPrinterHelper.subscriptionBtStatus!
                                        .cancel();
                                  } else {
                                    Navigator.of(context).pop();
                                  }
                                });
                              }
                            } else {
                              CherryToast.error(
                                toastDuration: const Duration(seconds: 2),
                                title: Text(
                                  "Please turn on bluetooth",
                                  style: CustomTextStyle.h4
                                      .copyWith(color: ColorTheme.danger),
                                ),
                                toastPosition: Position.bottom,
                                borderRadius: 5,
                              ).show(context);
                            }
                          }
                        : () => Navigator.of(context).pushReplacementNamed(
                              e.route!,
                            ),
              ),
            ),
          )
          .toList();
    }

    Future<void> syncDataToServer() async {
      if (syncData.totalDataNeedToSync > 0) {
        if (await checkBackgroundServiceStatusHelper.isRunning()) {
          if (!mounted) return;
          openAlert(
            context: context,
            content: 'Synchronization is running in background',
            textButton: 'I got it',
          );
        } else {
          await syncData.startSync(
            (isSyncing) {
              if (mounted) {
                print('[IS SYNCING] $isSyncing');
                setState(() {
                  isSyncingData = isSyncing;
                });
              }
            },
          );
          if (!mounted) return;
          openAlert(
            context: context,
            content:
                'Start syncing. You can keep using the app but do not close it. Thank you.',
            textButton: 'I got it',
          );
        }
      } else {
        openAlert(
          context: context,
          content: 'No data needs to be synced.',
          textButton: 'I got it',
        );
      }
    }

    List<NavItemMenu> navItem = [
      NavItemMenu(
        title:
            '${isSyncingData ? 'Syncing' : 'Sync'} (${syncData.totalDataNeedToSync})',
        icon: SvgPicture.asset('assets/svg/IconUpload.svg'),
        background: ColorTheme.lighterPrimary,
        check: true,
        colorText: ColorTheme.primary,
        setCheck: isSyncingData
            ? () {}
            : () async {
                await syncDataToServer();
              },
      ),
      NavItemMenu(
        title: '999',
        icon: SvgPicture.asset('assets/svg/IconCall3.svg'),
        route: HomeOverview.routeName,
        background: ColorTheme.grey200,
        check: null,
        setCheck: () async {
          final call = Uri.parse('tel:999');
          if (await canLaunchUrl(call)) {
            launchUrl(call);
          } else {
            throw 'Could not launch $call';
          }
        },
      ),
      NavItemMenu(
        title: 'Start break',
        icon: SvgPicture.asset('assets/svg/IconStartBreak.svg'),
        route: HomeOverview.routeName,
        check: true,
        colorText: ColorTheme.secondary,
        background: ColorTheme.lighterSecondary,
        setCheck: onStartBreak,
      ),
    ];
    List<Widget> getListNav() {
      return navItem
          .map((e) => NavItem(
                itemMenu: e,
              ))
          .toList();
    }

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    Widget containerDrawer(Widget children) {
      if (isLandscape) {
        return SingleChildScrollView(child: children);
      } else {
        return children;
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SizedBox(
        width: isLandscape ? widthScreen * 0.66 : widthScreen * 0.85,
        child: Drawer(
          child: containerDrawer(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: [
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 5),
                      child: InfoDrawer(
                        isDrawer: true,
                        assetImage: wardensProvider.wardens?.Picture ??
                            "assets/images/userAvatar.png",
                        name: "Hi ${wardensProvider.wardens?.FullName ?? ""}",
                        location: locations.location?.Name ?? 'Empty name',
                        zone: locations.zone?.PublicName ?? 'Empty name',
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getList(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: SpotCheck(),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Consumer<Auth>(
                      builder: (context, auth, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ItemMenuWidget(
                            itemMenu: ItemMenu(
                              "End shift",
                              'assets/svg/IconEndShift.svg',
                              null,
                            ),
                            onTap: () {
                              onEndShift(auth);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: getListNav(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      color: ColorTheme.grey200,
                      child: const VersionName(),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

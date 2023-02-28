import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/first-seen/add-first-seen/add_first_seen_screen.dart';
import 'package:iWarden/screens/grace-period/add_grace_period.dart';
import 'package:iWarden/screens/grace-period/index.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/screens/parking-charges/pcn_information/parking_charge_list.dart';
import 'package:iWarden/screens/start-break-screen/start_break_screen.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/drawer/info_drawer.dart';
import 'package:iWarden/widgets/home/card_home.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

List<String> fakeImages = [
  '/data/user/0/com.example.iWarden/cache/CAP1317129956677019721.jpg',
  '/data/user/0/com.example.iWarden/cache/CAP505075306031560444.jpg',
  '/data/user/0/com.example.iWarden/cache/CAP4469024442255754578.jpg',
  '/data/user/0/com.example.iWarden/cache/CAP4011318888943806994.jpg',
];

class HomeOverview extends StatefulWidget {
  static const routeName = '/home';
  const HomeOverview({Key? key}) : super(key: key);

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> {
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  List<VehicleInformation> firstSeenActive = [];
  List<VehicleInformation> firstSeenExpired = [];
  List<VehicleInformation> gracePeriodActive = [];
  List<VehicleInformation> gracePeriodExpired = [];
  List<Contravention> contraventionList = [];
  final calculateTime = CalculateTime();
  bool loading = false;
  late ZoneCachedServiceFactory zoneCachedServiceFactory;

  Future<void> syncAndGetData() async {
    setState(() {
      loading = true;
    });
    try {
      await zoneCachedServiceFactory.contraventionReasonCachedService
          .syncFromServer();
      await zoneCachedServiceFactory.contraventionCachedService
          .syncFromServer();
      await zoneCachedServiceFactory.firstSeenCachedService.syncFromServer();
      await zoneCachedServiceFactory.gracePeriodCachedService.syncFromServer();
    } catch (e) {}
    setState(() {
      loading = false;
    });
  }

  Future<void> getData() async {
    var listFirstSeen = await zoneCachedServiceFactory.firstSeenCachedService
        .getAllWithCreatedOnTheOffline();
    DateTime nowNTP = await timeNTP.get();
    print('[HomeOverview] $nowNTP');
    getFirstSeenActiveAndExpired(listFirstSeen, nowNTP);
    var gracePeriods = await zoneCachedServiceFactory.gracePeriodCachedService
        .getAllWithCreatedOnTheOffline();
    getGracePeriodActiveAndExpired(gracePeriods, nowNTP);
    var contraventions = await zoneCachedServiceFactory
        .contraventionCachedService
        .getAllWithCreatedOnTheOffline();
    setState(() {
      contraventionList = contraventions;
    });
    var contraventionReasons = await zoneCachedServiceFactory
        .contraventionReasonCachedService
        .getAll();
    setState(() {
      contraventionReasonList = contraventionReasons;
    });
  }

  getFirstSeenActiveAndExpired(
      List<VehicleInformation> vehicleList, DateTime now) {
    setState(() {
      firstSeenActive = vehicleList.where((i) {
        return calculateTime.daysBetween(
              i.Created!.add(
                Duration(
                  minutes: calculateTime.daysBetween(
                    i.Created as DateTime,
                    now,
                  ),
                ),
              ),
              i.ExpiredAt,
            ) >
            0;
      }).toList();

      firstSeenExpired = vehicleList.where((i) {
        return calculateTime.daysBetween(
              i.Created!.add(
                Duration(
                  minutes: calculateTime.daysBetween(
                    i.Created as DateTime,
                    now,
                  ),
                ),
              ),
              i.ExpiredAt,
            ) <=
            0;
      }).toList();
    });
  }

  getGracePeriodActiveAndExpired(
      List<VehicleInformation> vehicleList, DateTime now) {
    setState(() {
      gracePeriodActive = vehicleList.where((i) {
        return calculateTime.daysBetween(
              i.Created!.add(
                Duration(
                  minutes: calculateTime.daysBetween(
                    i.Created as DateTime,
                    now,
                  ),
                ),
              ),
              i.ExpiredAt,
            ) >
            0;
      }).toList();

      gracePeriodExpired = vehicleList.where((i) {
        return calculateTime.daysBetween(
              i.Created!.add(
                Duration(
                  minutes: calculateTime.daysBetween(
                    i.Created as DateTime,
                    now,
                  ),
                ),
              ),
              i.ExpiredAt,
            ) <=
            0;
      }).toList();
    });
  }

  bool checkHasOverstaying() {
    var overStaying =
        contraventionReasonList.firstWhereOrNull((e) => e.code == '36');
    if (overStaying != null) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final locationProvider = Provider.of<Locations>(context, listen: false);
      zoneCachedServiceFactory = locationProvider.zoneCachedServiceFactory;
      await getData();
    });
  }

  @override
  void dispose() {
    firstSeenActive.clear();
    firstSeenExpired.clear();
    gracePeriodActive.clear();
    gracePeriodExpired.clear();
    contraventionList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final locations = Provider.of<Locations>(context, listen: false);
    final wardensProvider = Provider.of<WardensInfo>(context);

    log('Home screen');

    final wardenEvent = WardenEvent(
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

    final wardenEventStartBreak = WardenEvent(
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

    void onCheckOut() async {
      try {
        showCircularProgressIndicator(context: context, text: 'Checking out');
        // eventAnalytics.clickButton(
        //   button: "Check out",
        //   user: wardensProvider.wardens!.Email,
        // );
        await createdWardenEventLocalService.create(wardenEvent).then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
        });
      } on DioError catch (error) {
        if (!mounted) return;
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

    void onStartBreak() async {
      // eventAnalytics.clickButton(
      //   button: "Start break",
      //   user: wardensProvider.wardens!.Email,
      // );
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

    Future<void> refresh() async {
      await syncAndGetData();
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: const MyAppBar(title: "Home"),
        drawer: const MyDrawer(),
        bottomNavigationBar: BottomSheet2(buttonList: [
          BottomNavyBarItem(
            onPressed: onStartBreak,
            icon: SvgPicture.asset(
              'assets/svg/IconStartBreak.svg',
              color: Colors.white,
            ),
            label: "Start break",
          ),
          BottomNavyBarItem(
            onPressed: onCheckOut,
            icon: SvgPicture.asset(
              "assets/svg/CheckOut.svg",
              color: ColorTheme.textPrimary,
            ),
            label: "Check out",
          ),
        ]),
        body: RefreshIndicator(
          onRefresh: refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: <Widget>[
                const SizedBox(
                  height: 10,
                ),
                InfoDrawer(
                  isDrawer: false,
                  assetImage: wardensProvider.wardens?.Picture ??
                      "assets/images/userAvatar.png",
                  name: "Hi ${wardensProvider.wardens?.FullName ?? ""}",
                  location: locations.location?.Name ?? 'Empty name',
                  zone: locations.zone?.PublicName ?? 'Empty name',
                ),
                const SizedBox(
                  height: 10,
                ),
                checkHasOverstaying() == true
                    ? loading == false
                        ? CardHome(
                            width: width,
                            assetIcon: "assets/svg/IconFirstSeen.svg",
                            backgroundIcon: ColorTheme.lighterPrimary,
                            title: "First seen",
                            infoRight: "Active: ${firstSeenActive.length}",
                            infoLeft: "Expired: ${firstSeenExpired.length}",
                            route: AddFirstSeenScreen.routeName,
                            routeView: ActiveFirstSeenScreen.routeName,
                          )
                        : SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              width: width,
                              height: 100,
                            ),
                          )
                    : const SizedBox(),
                checkHasOverstaying() == true
                    ? const SizedBox(
                        height: 10,
                      )
                    : const SizedBox(),
                loading == false
                    ? CardHome(
                        width: width,
                        assetIcon: "assets/svg/IconGrace.svg",
                        backgroundIcon: ColorTheme.lightDanger,
                        title: "Consideration period",
                        infoRight: "Active: ${gracePeriodActive.length}",
                        infoLeft: "Expired: ${gracePeriodExpired.length}",
                        route: AddGracePeriod.routeName,
                        routeView: GracePeriodList.routeName,
                      )
                    : SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: width,
                          height: 100,
                        ),
                      ),
                const SizedBox(
                  height: 10,
                ),
                loading == false
                    ? CardHome(
                        width: width,
                        assetIcon: "assets/svg/IconParkingChargesHome.svg",
                        backgroundIcon: ColorTheme.lighterSecondary,
                        title: "Parking charges",
                        infoRight: "Issued: ${contraventionList.length}",
                        infoLeft: null,
                        route: IssuePCNFirstSeenScreen.routeName,
                        routeView: ParkingChargeList.routeName,
                      )
                    : SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: width,
                          height: 100,
                        ),
                      ),
                // ElevatedButton(
                //     onPressed: () async {
                //       DateTime now = await timeNTP.get();
                //       print('[NTP] ${now}');
                //     },
                //     child: Text("geaâat")),
                // ElevatedButton(
                //     onPressed: () async {
                //       FlutterKronos.sync();
                //     },
                //     child: Text("get")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

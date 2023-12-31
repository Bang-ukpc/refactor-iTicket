import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/common/card_item.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/tabbar.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/models/first_seen.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/first-seen/active_detail_first_seen.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/first-seen/expired_detail_first_seen.dart';
import 'package:iWarden/screens/grace-period/add_grace_period.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../../helpers/my_navigator_observer.dart';
import '../../providers/time_ntp.dart';

class GracePeriodList extends StatefulWidget {
  static const routeName = '/grace-period-list';
  const GracePeriodList({super.key});

  @override
  BaseStatefulState<GracePeriodList> createState() => _GracePeriodListState();
}

class _GracePeriodListState extends BaseStatefulState<GracePeriodList> {
  List<VehicleInformation> gracePeriodActive = [];
  List<VehicleInformation> gracePeriodExpired = [];
  List<VehicleInformation> graceGracePeriodLocal = [];
  bool isLoading = false;
  final calculateTime = CalculateTime();
  String messageNullActive = 'Your active grace period list is empty';
  String messageNullExpired = 'Your expired grace period list is empty';
  late ZoneCachedServiceFactory zoneCachedServiceFactory;
  String textSearchVrn = '';

  Future<void> syncAndGetData(int zoneId) async {
    setState(() {
      isLoading = true;
    });
    try {
      await zoneCachedServiceFactory.gracePeriodCachedService.syncFromServer();
    } catch (e) {}
    if (textSearchVrn.isEmpty) {
      await getData(zoneId);
    } else {
      searchByVrn(textSearchVrn);
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getData(int zoneId) async {
    await getTimeNTP();
    await zoneCachedServiceFactory.gracePeriodCachedService
        .getListActive()
        .then((listActive) {
      setState(() {
        gracePeriodActive = listActive;
      });
    });
    var localVehicleData =
        await createdVehicleDataLocalService.getAllGracePeriod(zoneId);
    setState(() {
      graceGracePeriodLocal = localVehicleData;
    });
    zoneCachedServiceFactory.gracePeriodCachedService
        .getListExpired()
        .then((listExpired) {
      setState(() {
        gracePeriodExpired = listExpired;
      });
    });
  }

  DateTime nowNTP = DateTime.now();
  getTimeNTP() async {
    DateTime now = await timeNTP.get();
    setState(() {
      nowNTP = now;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      getTimeNTP();
      final locations = Provider.of<Locations>(context, listen: false);
      zoneCachedServiceFactory = locations.zoneCachedServiceFactory;
      await getData(locations.zone?.Id ?? 0);
    });
  }

  @override
  void dispose() {
    gracePeriodActive.clear();
    gracePeriodExpired.clear();
    textSearchVrn = '';
    super.dispose();
  }

  void searchByVrn(String vrn) async {
    final locations = Provider.of<Locations>(context, listen: false);
    if (vrn.isEmpty) {
      await getData(locations.zone?.Id ?? 0);
    }
    var localVehicleData = await zoneCachedServiceFactory
        .gracePeriodCachedService
        .getAllWithCreatedOnTheOffline();
    List<VehicleInformation> vehiclesFilter = localVehicleData
        .where((element) =>
            element.Plate.toUpperCase().contains(vrn.toUpperCase()))
        .toList();

    await zoneCachedServiceFactory.gracePeriodCachedService
        .filterListActive(vehiclesFilter)
        .then((value) {
      gracePeriodActive = value;
    });
    await zoneCachedServiceFactory.gracePeriodCachedService
        .filterListExpired(vehiclesFilter)
        .then((value) {
      gracePeriodExpired = value;
    });
    setState(() {});
    if (vrn.isNotEmpty) {
      if (gracePeriodActive.isEmpty || gracePeriodExpired.isEmpty) {
        setState(() {
          messageNullActive =
              "The vehicle number plate '$vrn' does not exist in the list";
          messageNullExpired =
              "The vehicle number plate '$vrn' does not exist in the list";
        });
      }
    } else {
      setState(() {
        messageNullActive = 'Your active grace period list is empty';
        messageNullExpired = 'Your expired grace period list is empty';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context);
    log('Grace period list screen');

    void onCarLeft(VehicleInformation vehicleInfo) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            title: Text(
              "Confirm",
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            subTitle: const Text(
              "Confirm the vehicle has left.",
              style: CustomTextStyle.h5,
            ),
            func: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorTheme.danger,
              ),
              child: Text("Proceed",
                  style: CustomTextStyle.h5.copyWith(
                    color: Colors.white,
                  )),
              onPressed: () async {
                showCircularProgressIndicator(context: context);
                await createdVehicleDataLocalService.onCarLeft(vehicleInfo);
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                await getData(locations.zone?.Id ?? 0);
              },
            ),
          );
        },
      );
    }

    Future<void> refresh() async {
      await syncAndGetData(locations.zone?.Id ?? 0);
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: MyTabBar(
          searchByVrn: (e) {
            searchByVrn(e);
            setState(() {
              textSearchVrn = e;
            });
          },
          resetValueSearch: () async {
            await getData(locations.zone?.Id ?? 0);
            setState(() {
              messageNullActive = 'Your active grace period list is empty';
              messageNullExpired = 'Your expired grace period list is empty';
              textSearchVrn = '';
            });
          },
          labelFuncAdd: "Add consideration period",
          titleAppBar: "Consideration period",
          funcAdd: () {
            Navigator.of(context)
                .pushReplacementNamed(AddGracePeriod.routeName);
          },
          tabBarViewTab1: RefreshIndicator(
            onRefresh: refresh,
            child: isLoading == false
                ? gracePeriodActive.isNotEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: gracePeriodActive.length > 3
                              ? (gracePeriodActive.length.toDouble()) * 110
                              : 350,
                          margin: const EdgeInsets.only(
                              bottom: ConstSpacing.bottom),
                          child: Column(
                            children: gracePeriodActive
                                .map(
                                  (item) => CardItem(
                                    isOffline: graceGracePeriodLocal
                                            .firstWhereOrNull((element) =>
                                                element.Id == item.Id) !=
                                        null,
                                    vehicleInfo: item,
                                    type: TypeFirstSeen.Active,
                                    expiring: calculateTime.daysBetween(
                                      item.Created!.add(
                                        Duration(
                                          minutes: calculateTime.daysBetween(
                                            item.Created as DateTime,
                                            nowNTP,
                                          ),
                                        ),
                                      ),
                                      item.ExpiredAt,
                                    ),
                                    onCarLeft: () {
                                      onCarLeft(item);
                                    },
                                    route: DetailActiveFirstSeen.routeName,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.asset(
                                  'assets/images/empty-list.png',
                                  color: ColorTheme.grey600,
                                ),
                              ),
                              Text(
                                messageNullActive,
                                style: CustomTextStyle.body1.copyWith(
                                  color: ColorTheme.grey600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          tabBarViewTab2: RefreshIndicator(
            onRefresh: refresh,
            child: isLoading == false
                ? gracePeriodExpired.isNotEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: gracePeriodExpired.length > 3
                              ? (gracePeriodExpired.length.toDouble() * 110)
                              : 350,
                          margin: const EdgeInsets.only(
                              bottom: ConstSpacing.bottom),
                          child: Column(
                            children: gracePeriodExpired
                                .map(
                                  (item) => CardItem(
                                    isOffline: graceGracePeriodLocal
                                            .firstWhereOrNull((element) =>
                                                element.Id == item.Id) !=
                                        null,
                                    vehicleInfo: item,
                                    type: TypeFirstSeen.Expired,
                                    expiring: calculateTime.daysBetween(
                                      item.ExpiredAt,
                                      nowNTP,
                                    ),
                                    onCarLeft: () {
                                      onCarLeft(item);
                                    },
                                    route: DetailExpiredFirstSeen.routeName,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.asset(
                                  'assets/images/empty-list.png',
                                  color: ColorTheme.grey600,
                                ),
                              ),
                              Text(
                                messageNullExpired,
                                style: CustomTextStyle.body1.copyWith(
                                  color: ColorTheme.grey600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          quantityActive: gracePeriodActive.length,
          quantityExpired: gracePeriodExpired.length,
        ),
      ),
    );
  }
}

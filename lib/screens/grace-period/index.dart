import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iWarden/common/card_item.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/tabbar.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/models/first_seen.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/first-seen/active_detail_first_seen.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/first-seen/expired_detail_first_seen.dart';
import 'package:iWarden/screens/grace-period/add_grace_period.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class GracePeriodList extends StatefulWidget {
  static const routeName = '/grace-period-list';
  const GracePeriodList({super.key});

  @override
  State<GracePeriodList> createState() => _GracePeriodListState();
}

class _GracePeriodListState extends State<GracePeriodList> {
  List<VehicleInformation> gracePeriodActive = [];
  List<VehicleInformation> gracePeriodExpired = [];
  bool gracePeriodLoading = true;
  final calculateTime = CalculateTime();

  late ZoneCachedServiceFactory zoneCachedServiceFactory;

  getData() {
    zoneCachedServiceFactory.gracePeriodCachedService
        .getListActive()
        .then((listActive) {
      setState(() {
        gracePeriodActive = listActive;
      });
    });

    zoneCachedServiceFactory.gracePeriodCachedService
        .getListExpired()
        .then((listExpired) {
      setState(() {
        gracePeriodExpired = listExpired;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final locations = Provider.of<Locations>(context, listen: false);
      zoneCachedServiceFactory = locations.zoneCachedServiceFactory;
      getData();
    });
  }

  @override
  void dispose() {
    gracePeriodActive.clear();
    gracePeriodExpired.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context, listen: false);

    log('Grace period list screen');

    void onCarLeft(VehicleInformation vehicleInfo) {
      VehicleInformation vehicleInfoToUpdate = VehicleInformation(
        ExpiredAt: vehicleInfo.ExpiredAt,
        Plate: vehicleInfo.Plate,
        ZoneId: vehicleInfo.ZoneId,
        LocationId: vehicleInfo.LocationId,
        BayNumber: vehicleInfo.BayNumber,
        Type: vehicleInfo.Type,
        Latitude: vehicleInfo.Latitude,
        Longitude: vehicleInfo.Longitude,
        CarLeft: true,
        EvidencePhotos: [],
        Id: vehicleInfo.Id,
      );

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
                await VehicleInfoController()
                    .upsertVehicleInfo(vehicleInfoToUpdate)
                    .then((value) {
                  if (value != null) {
                    Navigator.of(context).pop();
                    getData();
                  }
                });
              },
            ),
          );
        },
      );
    }

    Future<void> refresh() async {
      getData();
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: MyTabBar(
          labelFuncAdd: "Add consideration period",
          titleAppBar: "Consideration period",
          funcAdd: () {
            Navigator.of(context)
                .pushReplacementNamed(AddGracePeriod.routeName);
          },
          tabBarViewTab1: RefreshIndicator(
            onRefresh: refresh,
            child: gracePeriodLoading == true
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
                                    vehicleInfo: item,
                                    type: TypeFirstSeen.Active,
                                    expiring: calculateTime.daysBetween(
                                      item.Created!.add(
                                        Duration(
                                          minutes: calculateTime.daysBetween(
                                            item.Created as DateTime,
                                            DateTime.now(),
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
                    : Center(
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
                              'Your active grace period list is empty',
                              style: CustomTextStyle.body1.copyWith(
                                color: ColorTheme.grey600,
                              ),
                            ),
                          ],
                        ),
                      )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          tabBarViewTab2: RefreshIndicator(
            onRefresh: refresh,
            child: gracePeriodLoading == true
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
                                    vehicleInfo: item,
                                    type: TypeFirstSeen.Expired,
                                    expiring: calculateTime.daysBetween(
                                      item.ExpiredAt,
                                      DateTime.now(),
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
                    : Center(
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
                              'Your expired grace period list is empty',
                              style: CustomTextStyle.body1.copyWith(
                                color: ColorTheme.grey600,
                              ),
                            ),
                          ],
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

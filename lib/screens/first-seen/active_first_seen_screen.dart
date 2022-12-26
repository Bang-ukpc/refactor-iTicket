import 'dart:async';
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
import 'package:iWarden/screens/first-seen/add-first-seen/add_first_seen_screen.dart';
import 'package:iWarden/screens/first-seen/expired_detail_first_seen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class ActiveFirstSeenScreen extends StatefulWidget {
  static const routeName = '/first-seen';
  const ActiveFirstSeenScreen({Key? key}) : super(key: key);

  @override
  State<ActiveFirstSeenScreen> createState() => _ActiveFirstSeenScreenState();
}

class _ActiveFirstSeenScreenState extends State<ActiveFirstSeenScreen> {
  List<VehicleInformation> firstSeenActive = [];
  List<VehicleInformation> firstSeenExpired = [];
  bool firstSeenLoading = true;
  final calculateTime = CalculateTime();

  void getFirstSeenList(
      {required int page, required int pageSize, required int zoneId}) async {
    final Pagination list = await vehicleInfoController
        .getVehicleInfoList(
      vehicleInfoType: VehicleInformationType.FIRST_SEEN.index,
      zoneId: zoneId,
      page: page,
      pageSize: pageSize,
    )
        .then((value) {
      setState(() {
        firstSeenLoading = false;
      });
      return value;
    }).catchError((err) {
      setState(() {
        firstSeenLoading = false;
      });
    });
    final firstSeenList =
        list.rows.map((item) => VehicleInformation.fromJson(item)).toList();
    getFirstSeenActiveAndExpired(firstSeenList);
  }

  void getFirstSeenActiveAndExpired(List<VehicleInformation> vehicleList) {
    setState(() {
      firstSeenActive = vehicleList.where((i) {
        return calculateTime.daysBetween(
              i.Created!.add(
                Duration(
                  minutes: calculateTime.daysBetween(
                    i.Created as DateTime,
                    DateTime.now(),
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
                    DateTime.now(),
                  ),
                ),
              ),
              i.ExpiredAt,
            ) <=
            0;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final locations = Provider.of<Locations>(context, listen: false);
      getFirstSeenList(
        page: 1,
        pageSize: 1000,
        zoneId: locations.zone!.Id as int,
      );
    });
  }

  @override
  void dispose() {
    firstSeenActive.clear();
    firstSeenExpired.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context, listen: false);

    log('Active first seen screen');

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
                  Navigator.of(context).pop();
                  getFirstSeenList(
                    page: 1,
                    pageSize: 1000,
                    zoneId: locations.zone!.Id as int,
                  );
                });
              },
            ),
          );
        },
      );
    }

    Future<void> refresh() async {
      getFirstSeenList(
        page: 1,
        pageSize: 1000,
        zoneId: locations.zone!.Id as int,
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: MyTabBar(
        labelFuncAdd: "Add first seen",
        titleAppBar: "First seen",
        funcAdd: () {
          Navigator.of(context)
              .pushReplacementNamed(AddFirstSeenScreen.routeName);
        },
        tabBarViewTab1: RefreshIndicator(
          onRefresh: refresh,
          child: firstSeenLoading == false
              ? firstSeenActive.isNotEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: ConstSpacing.bottom),
                        child: Column(
                          children: firstSeenActive
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
                            'Your active first seen list is empty',
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
          child: firstSeenLoading == false
              ? firstSeenExpired.isNotEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: ConstSpacing.bottom),
                        child: Column(
                          children: firstSeenExpired
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
                            'Your expired first seen list is empty',
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
        quantityActive: firstSeenActive.length,
        quantityExpired: firstSeenExpired.length,
      ),
    );
  }
}

class CalculateTime {
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day, from.hour, from.minute);
    to = DateTime(to.year, to.month, to.day, to.hour, to.minute);
    return (to.difference(from).inMinutes);
  }

  String getDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(1);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours.remainder(24));
    return "${twoDigitHours}hr ${twoDigitMinutes}min";
  }

  String getDurationExpiredIn(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(1);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours.remainder(24));
    return "${twoDigits(duration.inDays)}d ${twoDigitHours}hr ${twoDigitMinutes}min";
  }
}

class ServerError extends StatelessWidget {
  const ServerError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 50,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Internal server error!',
              style: TextStyle(
                color: ColorTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

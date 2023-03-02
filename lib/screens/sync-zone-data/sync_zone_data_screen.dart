import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/circle.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../../helpers/my_navigator_observer.dart';

class SyncZoneData extends StatefulWidget {
  static const routeName = '/sync-zone-data';
  const SyncZoneData({super.key});

  @override
  BaseStatefulState<SyncZoneData> createState() => _SyncZoneDataState();
}

class _SyncZoneDataState extends BaseStatefulState<SyncZoneData> {
  late ZoneCachedServiceFactory zoneCachedServiceFactory;
  bool isPulledData = false;
  bool isLatestFirstSeen = false;
  bool isLatestGracePeriod = false;
  bool isLatestContraventions = false;

  _buildConnect(String title, StateDevice state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 19),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: CustomTextStyle.h5,
              ),
            ],
          ),
          Row(
            children: [
              if (state == StateDevice.pending)
                SpinKitCircle(
                  color: ColorTheme.primary,
                  size: 18,
                ),
              if ((state == StateDevice.disconnect))
                SvgPicture.asset(
                  "assets/svg/IconDotYellow.svg",
                ),
              if (state == StateDevice.connected)
                SvgPicture.asset("assets/svg/IconCompleteActive.svg")
            ],
          ),
        ],
      ),
    );
  }

  StateDevice checkState(bool check) {
    if (check) {
      return StateDevice.connected;
    } else {
      return StateDevice.disconnect;
    }
  }

  Future<void> syncZoneData() async {
    await getContraventions();

    try {
      await zoneCachedServiceFactory.contraventionReasonCachedService
          .syncFromServer();
    } catch (e) {}

    await getListFirstSeen();

    await getGracePeriods();
  }

  Future<void> getListFirstSeen() async {
    try {
      await zoneCachedServiceFactory.firstSeenCachedService
          .syncFromServer()
          .then((value) {
        print("[value.length] ${value.length}");
      });
      setState(() {
        isLatestFirstSeen = true;
      });
    } catch (e) {
      setState(() {
        isLatestFirstSeen = false;
      });
    }
  }

  Future<void> getGracePeriods() async {
    try {
      await zoneCachedServiceFactory.gracePeriodCachedService.syncFromServer();
      setState(() {
        isLatestGracePeriod = true;
      });
    } catch (e) {
      setState(() {
        isLatestGracePeriod = false;
      });
    }
  }

  Future<void> getContraventions() async {
    try {
      await zoneCachedServiceFactory.contraventionCachedService
          .syncFromServer();
      setState(() {
        isLatestContraventions = true;
      });
    } catch (e) {
      setState(() {
        isLatestContraventions = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final locationProvider = Provider.of<Locations>(context, listen: false);
      print("[SYNC ZONE DATA] with zoneID is ${locationProvider.zone?.Id}");
      zoneCachedServiceFactory = locationProvider.zoneCachedServiceFactory;
      await syncZoneData();
      setState(() {
        isPulledData = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> refresh() async {
      setState(() {
        isPulledData = false;
      });
      await syncZoneData();
      setState(() {
        isPulledData = true;
      });
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 60,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Data synchronisation",
                          style: CustomTextStyle.h3
                              .copyWith(color: ColorTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        isPulledData
                            ? _buildConnect(
                                "1. First seen list",
                                checkState(isLatestFirstSeen),
                              )
                            : _buildConnect(
                                '1. First seen list', StateDevice.pending),
                        isPulledData
                            ? _buildConnect(
                                "2. Consideration period list",
                                checkState(isLatestGracePeriod),
                              )
                            : _buildConnect('2. Consideration period list',
                                StateDevice.pending),
                        isPulledData
                            ? _buildConnect(
                                "3. Contravention list",
                                checkState(isLatestContraventions),
                              )
                            : _buildConnect(
                                '3. Contravention list', StateDevice.pending),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  if (isPulledData)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: SvgPicture.asset(
                                "assets/svg/IconNext.svg",
                                color: Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    HomeOverview.routeName,
                                    (Route<dynamic> route) => false);
                              },
                              label: Text(
                                "Next",
                                style: CustomTextStyle.h5.copyWith(
                                    color: Colors.white, fontSize: 16),
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
      ),
    );
  }
}

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

class SyncZoneData extends StatefulWidget {
  static const routeName = '/sync-zone-data';
  const SyncZoneData({super.key});

  @override
  State<SyncZoneData> createState() => _SyncZoneDataState();
}

class _SyncZoneDataState extends State<SyncZoneData> {
  late ZoneCachedServiceFactory zoneCachedServiceFactory;
  bool isPulledData = false;
  bool isListFirstSeenNotNull = false;
  bool isGracePeriodsNotNull = false;
  bool isContraventionsNotNull = false;

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
              if (state == StateDevice.disconnect)
                SvgPicture.asset(
                  "assets/svg/IconDotCom.svg",
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
    await zoneCachedServiceFactory.contraventionCachedService.syncFromServer();
    await getContraventions();

    await zoneCachedServiceFactory.contraventionReasonCachedService
        .syncFromServer();

    await zoneCachedServiceFactory.firstSeenCachedService.syncFromServer();
    await getListFirstSeen();

    await zoneCachedServiceFactory.gracePeriodCachedService.syncFromServer();
    await getGracePeriods();
  }

  Future<void> getListFirstSeen() async {
    var listFirstSeen =
        await zoneCachedServiceFactory.firstSeenCachedService.getAll();
    setState(() {
      isListFirstSeenNotNull = listFirstSeen.isNotEmpty;
    });
  }

  Future<void> getGracePeriods() async {
    var gracePeriods =
        await zoneCachedServiceFactory.gracePeriodCachedService.getAll();
    setState(() {
      isGracePeriodsNotNull = gracePeriods.isNotEmpty;
    });
  }

  Future<void> getContraventions() async {
    var contraventions =
        await zoneCachedServiceFactory.contraventionCachedService.getAll();
    setState(() {
      isContraventionsNotNull = contraventions.isNotEmpty;
    });
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
                          "Pull location’s data",
                          style: CustomTextStyle.h3
                              .copyWith(color: ColorTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        isPulledData
                            ? _buildConnect(
                                "1. First seen list",
                                checkState(isListFirstSeenNotNull),
                              )
                            : _buildConnect(
                                '1. First seen list', StateDevice.pending),
                        isPulledData
                            ? _buildConnect(
                                "2. Consideration period list",
                                checkState(isGracePeriodsNotNull),
                              )
                            : _buildConnect('2. Consideration period list',
                                StateDevice.pending),
                        isPulledData
                            ? _buildConnect(
                                "3. Contravention list",
                                checkState(isContraventionsNotNull),
                              )
                            : _buildConnect(
                                '3. Contravention list', StateDevice.pending),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/screens/parking-charges/pcn_information/parking_charge_detail.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/services/local/issued_pcn_local_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/card_item.dart';
import 'package:provider/provider.dart';

import '../../../helpers/my_navigator_observer.dart';

class ParkingChargeList extends StatefulWidget {
  static const routeName = 'parking-charges-list';
  const ParkingChargeList({super.key});

  @override
  BaseStatefulState<ParkingChargeList> createState() =>
      _ParkingChargeListState();
}

class _ParkingChargeListState extends BaseStatefulState<ParkingChargeList> {
  List<Contravention> contraventionList = [];
  bool contraventionLoading = false;
  bool loadingImage = true;
  late ZoneCachedServiceFactory zoneCachedServiceFactory;
  List<ContraventionCreateWardenCommand> issuedContraventions = [];

  Future<void> syncAndGetData() async {
    setState(() {
      contraventionLoading = true;
    });
    try {
      await zoneCachedServiceFactory.contraventionCachedService
          .syncFromServer();
    } catch (e) {}
    await getData();
    setState(() {
      contraventionLoading = false;
    });
  }

  Future<void> getData() async {
    var contraventions = await zoneCachedServiceFactory
        .contraventionCachedService
        .getAllWithCreatedOnTheOffline();

    var localIssuedContraventions = await issuedPcnLocalService.getAll();

    setState(() {
      contraventionList = contraventions;
      issuedContraventions = localIssuedContraventions;
    });
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
    contraventionList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> refresh() async {
      await syncAndGetData();
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: 'Parking charges',
          automaticallyImplyLeading: true,
          onRedirect: () {
            Navigator.of(context).pushNamed(HomeOverview.routeName);
          },
        ),
        drawer: const MyDrawer(),
        bottomNavigationBar: BottomSheet2(buttonList: [
          BottomNavyBarItem(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(IssuePCNFirstSeenScreen.routeName);
            },
            icon: SvgPicture.asset(
              "assets/svg/IconCharges2.svg",
              width: 16,
              color: Colors.white,
            ),
            label: 'Issue PCN',
          ),
        ]),
        body: RefreshIndicator(
          onRefresh: refresh,
          child: contraventionLoading == false
              ? contraventionList.isNotEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        margin: const EdgeInsets.only(top: 5, bottom: 100),
                        child: Column(
                          children: contraventionList
                              .map(
                                (item) => InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      ParkingChargeDetail.routeName,
                                      arguments: item,
                                    );
                                  },
                                  child: CardItemParkingCharge(
                                    isOffline: issuedContraventions
                                            .firstWhereOrNull((element) =>
                                                element.Id == item.id) !=
                                        null,
                                    image: item.contraventionPhotos!.isNotEmpty
                                        ? item.contraventionPhotos![0].blobName
                                        : "",
                                    plate: item.plate as String,
                                    contraventions: item.reason
                                            ?.contraventionReasonTranslations ??
                                        [],
                                    created: item.eventDateTime as DateTime,
                                  ),
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
                            'Your Parking charges list is empty',
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
      ),
    );
  }
}

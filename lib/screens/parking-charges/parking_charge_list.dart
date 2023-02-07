import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_detail.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/card_item.dart';
import 'package:provider/provider.dart';

class ParkingChargeList extends StatefulWidget {
  static const routeName = 'parking-charges-list';
  const ParkingChargeList({super.key});

  @override
  State<ParkingChargeList> createState() => _ParkingChargeListState();
}

class _ParkingChargeListState extends State<ParkingChargeList> {
  List<Contravention> contraventionList = [];
  bool contraventionLoading = true;
  bool loadingImage = true;
  Future<List<Contravention>> getContraventionList(
      {required int page, required int pageSize, required int zoneId}) async {
    final Pagination list = await contraventionController
        .getContraventionServiceList(
      zoneId: zoneId,
      page: page,
      pageSize: pageSize,
    )
        .then((value) {
      setState(() {
        contraventionLoading = false;
      });
      return value;
    }).catchError((err) {
      setState(() {
        contraventionLoading = false;
      });
      throw Error();
    });
    contraventionList =
        list.rows.map((item) => Contravention.fromJson(item)).toList();
    return contraventionList;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final locations = Provider.of<Locations>(context, listen: false);
      getContraventionList(
        page: 1,
        pageSize: 1000,
        zoneId: locations.zone!.Id as int,
      );
    });
  }

  @override
  void dispose() {
    contraventionList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context, listen: false);
    log('Parking charge list');

    Future<void> refresh() async {
      getContraventionList(
        page: 1,
        pageSize: 1000,
        zoneId: locations.zone!.Id as int,
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: 'Parking changes',
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
                                    image: item.contraventionPhotos!.isNotEmpty
                                        ? item.contraventionPhotos![0].blobName
                                        : "",
                                    plate: item.plate as String,
                                    contraventions: item.reason
                                            ?.contraventionReasonTranslations ??
                                        [],
                                    created: item.created as DateTime,
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
                            'Your Parking changes list is empty',
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

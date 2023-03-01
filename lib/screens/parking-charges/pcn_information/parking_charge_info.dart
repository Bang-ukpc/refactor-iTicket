import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/parking-charges/pcn_information/parking_charge_list.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/detail_parking_common.dart';

import '../../../helpers/my_navigator_observer.dart';

class ParkingChargeInfo extends StatefulWidget {
  static const routeName = '/parking-charge-info';
  const ParkingChargeInfo({super.key});

  @override
  BaseStatefulState<ParkingChargeInfo> createState() =>
      _ParkingChargeInfoState();
}

class _ParkingChargeInfoState extends BaseStatefulState<ParkingChargeInfo> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Contravention;

    log('Parking charge info');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: "View PCN",
          automaticallyImplyLeading: true,
          isOpenDrawer: true,
          onRedirect: () {
            Navigator.of(context).pushNamed(ParkingChargeList.routeName);
          },
        ),
        drawer: const MyDrawer(),
        body: DetailParkingCommon(
          contravention: args,
          isDisplayBottomNavigate: true,
        ),
      ),
    );
  }
}

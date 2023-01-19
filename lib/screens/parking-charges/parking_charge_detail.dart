import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/detail_parking_common.dart';

class ParkingChargeDetail extends StatelessWidget {
  static const routeName = '/parking-charge-detail';
  const ParkingChargeDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Contravention;

    log('Parking charge detail');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: "View PCN",
          automaticallyImplyLeading: true,
          onRedirect: () {
            Navigator.of(context).pop();
          },
        ),
        drawer: const MyDrawer(),
        body: DetailParkingCommon(contravention: args),
      ),
    );
  }
}

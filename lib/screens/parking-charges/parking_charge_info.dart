import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/detail_parking_common.dart';

class ParkingChargeInfo extends StatefulWidget {
  static const routeName = '/parking-charge-info';
  const ParkingChargeInfo({super.key});

  @override
  State<ParkingChargeInfo> createState() => _ParkingChargeInfoState();
}

class _ParkingChargeInfoState extends State<ParkingChargeInfo> {
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
          onRedirect: () {
            Navigator.of(context).popAndPushNamed(ParkingChargeList.routeName);
          },
        ),
        drawer: const MyDrawer(),
        body: FutureBuilder(
          future:
              contraventionController.getContraventionDetail(args.id as int),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DetailParkingCommon(
                contravention: snapshot.data as Contravention,
                isDisplayBottomNavigate: true,
              );
            } else if (snapshot.hasError) {
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
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Go back!',
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

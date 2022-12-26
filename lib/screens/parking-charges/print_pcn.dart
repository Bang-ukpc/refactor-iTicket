import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/print_issue.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/detail_parking_common.dart';

class PrintPCN extends StatefulWidget {
  static const routeName = '/print-pcn';
  const PrintPCN({super.key});

  @override
  State<PrintPCN> createState() => _PrintPCNState();
}

class _PrintPCNState extends State<PrintPCN> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Contravention;

    log('Print pcn');

    return WillPopScope(
      onWillPop: () async => false,
      child: FutureBuilder(
        future: contraventionController.getContraventionDetail(args.id as int),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              drawer: const MyDrawer(),
              bottomSheet: BottomSheet2(
                buttonList: [
                  BottomNavyBarItem(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AbortScreen.routeName,
                        arguments: snapshot.data as Contravention,
                      );
                    },
                    icon: SvgPicture.asset('assets/svg/IconAbort.svg'),
                    label: const Text(
                      'Abort',
                      style: CustomTextStyle.h6,
                    ),
                  ),
                  BottomNavyBarItem(
                    onPressed: () {},
                    icon: SvgPicture.asset('assets/svg/IconPrinter.svg'),
                    label: const Text(
                      'Print again',
                      style: CustomTextStyle.h6,
                    ),
                  ),
                  BottomNavyBarItem(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        PrintIssue.routeName,
                        arguments: snapshot.data as Contravention,
                      );
                    },
                    icon: SvgPicture.asset('assets/svg/IconComplete.svg'),
                    label: const Text(
                      'Complete',
                      style: CustomTextStyle.h6,
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: DetailParkingCommon(
                  contravention: snapshot.data as Contravention,
                  isDisplayPrintPCN: true,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              drawer: const MyDrawer(),
              body: Center(
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
              ),
            );
          } else {
            return const Scaffold(
              drawer: MyDrawer(),
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}

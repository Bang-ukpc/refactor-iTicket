import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/helpers/bluetooth_printer.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/screens/parking-charges/print_pcn.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/step_issue_pcn.dart';
import 'package:iWarden/widgets/parking-charge/take_photo_item.dart';
import 'package:provider/provider.dart';

class PrintIssue extends StatefulWidget {
  static const routeName = '/print-issue';
  const PrintIssue({super.key});

  @override
  State<PrintIssue> createState() => _PrintIssueState();
}

class _PrintIssueState extends State<PrintIssue> {
  final _debouncer = Debouncer(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    bluetoothPrinterHelper.scan();
    bluetoothPrinterHelper.initConnect(isLoading: false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final locations = Provider.of<Locations>(context, listen: false);
      final contraventionProvider =
          Provider.of<ContraventionProvider>(context, listen: false);

      if (contraventionProvider.contravention!.type == TypePCN.Physical.index) {
        if (bluetoothPrinterHelper.selectedPrinter == null) {
          showCircularProgressIndicator(
            context: context,
            text: 'Connecting to printer',
          );
          _debouncer.run(() {
            Navigator.of(context).pop();
            CherryToast.error(
              toastDuration: const Duration(seconds: 5),
              title: Text(
                "Can't connect to a printer. Enable Bluetooth on both mobile device and printer and check that devices are paired.",
                style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);
          });
        } else {
          bluetoothPrinterHelper.printPhysicalPCN(
              contraventionProvider.contravention as Contravention,
              locations.location?.Name ?? '');
        }
      }
    });
  }

  @override
  void dispose() {
    print('disposed');
    bluetoothPrinterHelper.disposePrinter();
    if (_debouncer.timer != null) {
      _debouncer.timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final printIssue = Provider.of<PrintIssueProviders>(context);
    final contraventionProvider = Provider.of<ContraventionProvider>(context);
    log('Print issue');

    void takeAPhoto() async {
      await printIssue.getIdIssue(printIssue
          .findIssueNoImage(typePCN: contraventionProvider.contravention!.type)
          .id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraPicker(
            titleCamera: printIssue
                .findIssueNoImage(
                    typePCN: contraventionProvider.contravention!.type)
                .title,
            previewImage: true,
            onDelete: (file) {
              return true;
            },
          ),
        ),
      );
    }

    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            title: const Text("Cannot complete"),
            subTitle: const Text(
              "Please take enough proof photos to complete.",
              textAlign: TextAlign.center,
              style: CustomTextStyle.body1,
            ),
            func: ElevatedButton(
              child: const Text("Ok"),
              onPressed: () async {
                Navigator.of(context).pop();
                takeAPhoto();
              },
            ),
          );
        },
      );
    }

    void onCompleteTakePhotos() async {
      Contravention contraventionData =
          contraventionProvider.contravention as Contravention;
      bool check = false;
      List<ContraventionPhotos> contraventionImageList = [];
      showCircularProgressIndicator(context: context);

      if (printIssue.data.isNotEmpty) {
        for (int i = 0; i < printIssue.data.length; i++) {
          if (contraventionProvider.contravention!.type ==
              TypePCN.Virtual.index) {
            if (printIssue.data[i].image != null &&
                printIssue.data[i].id != 2) {
              contraventionImageList.add(ContraventionPhotos(
                blobName: printIssue.data[i].image!.path,
                contraventionId: contraventionProvider.contravention?.id ?? 0,
              ));
            }
          } else {
            if (printIssue.data[i].image != null) {
              contraventionImageList.add(ContraventionPhotos(
                blobName: printIssue.data[i].image!.path,
                contraventionId: contraventionProvider.contravention?.id ?? 0,
              ));
            }
          }
          if (i == printIssue.data.length - 1) {
            check = true;
          }
        }
      }
      if (check == true) {
        contraventionData.contraventionPhotos = contraventionImageList;
        contraventionProvider.upDateContravention(contraventionData);
        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(PrintPCN.routeName);
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          bottomNavigationBar: Consumer<Locations>(
            builder: (context, locations, child) =>
                BottomSheet2(padding: 5, buttonList: [
              BottomNavyBarItem(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AbortScreen.routeName,
                  );
                },
                icon: SvgPicture.asset('assets/svg/IconAbort.svg'),
                label: const Text(
                  'Abort',
                  style: CustomTextStyle.h6,
                ),
              ),
              if (contraventionProvider.contravention!.type ==
                  TypePCN.Physical.index)
                BottomNavyBarItem(
                  onPressed: () {
                    if (bluetoothPrinterHelper.selectedPrinter == null) {
                      showCircularProgressIndicator(
                        context: context,
                        text: 'Connecting to printer',
                      );
                      _debouncer.run(() {
                        Navigator.of(context).pop();
                        CherryToast.error(
                          toastDuration: const Duration(seconds: 5),
                          title: Text(
                            "Can't connect to a printer. Enable Bluetooth on both mobile device and printer and check that devices are paired.",
                            style: CustomTextStyle.h5
                                .copyWith(color: ColorTheme.danger),
                          ),
                          toastPosition: Position.bottom,
                          borderRadius: 5,
                        ).show(context);
                      });
                    } else {
                      bluetoothPrinterHelper.printPhysicalPCN(
                          contraventionProvider.contravention as Contravention,
                          locations.location?.Name ?? '');
                    }
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/IconPrinter.svg',
                    color: ColorTheme.textPrimary,
                  ),
                  label: const Text(
                    'Re-print',
                    style: CustomTextStyle.h6,
                  ),
                ),
              BottomNavyBarItem(
                onPressed: () {
                  if (printIssue
                              .findIssueNoImage(
                                  typePCN:
                                      contraventionProvider.contravention!.type)
                              .title !=
                          'null' &&
                      printIssue.checkIssueHasPhotoRequirePhysical() == false) {
                    showMyDialog();
                  } else {
                    onCompleteTakePhotos();
                  }
                },
                icon: SvgPicture.asset('assets/svg/IconNext.svg'),
                label: const Text(
                  'Next',
                  style: CustomTextStyle.h6,
                ),
              ),
            ]),
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: ColorTheme.white,
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          "Issue PCN",
                          style: CustomTextStyle.h4
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                StepIssuePCN(
                                  isActiveStep1: false,
                                  onTap1: contraventionProvider.contravention !=
                                          null
                                      ? () {
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                                  IssuePCNFirstSeenScreen
                                                      .routeName);
                                        }
                                      : null,
                                  isActiveStep2: true,
                                  isActiveStep3: false,
                                  onTap3: contraventionProvider.contravention !=
                                          null
                                      ? contraventionProvider.contravention!
                                              .contraventionPhotos!.isNotEmpty
                                          ? () {
                                              onCompleteTakePhotos();
                                            }
                                          : null
                                      : null,
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "Please take required photos as below:",
                                  style: CustomTextStyle.h5.copyWith(
                                    color: ColorTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Consumer<PrintIssueProviders>(
                                    builder: (_, value, __) {
                                  var filterImageByTypePCN =
                                      value.data.where((e) {
                                    if (contraventionProvider
                                            .contravention!.type ==
                                        TypePCN.Virtual.index) {
                                      return e.id != 2;
                                    }
                                    return true;
                                  }).toList();
                                  return Column(
                                    children: filterImageByTypePCN
                                        .map(
                                          (e) => TakePhotoItem(
                                            func: () async {
                                              await printIssue.getIdIssue(printIssue
                                                  .findIssueNoImage(
                                                      typePCN:
                                                          contraventionProvider
                                                              .contravention!
                                                              .type)
                                                  .id);
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CameraPicker(
                                                    typePCN:
                                                        contraventionProvider
                                                            .contravention!
                                                            .type,
                                                    titleCamera: printIssue
                                                        .findIssueNoImage(
                                                            typePCN:
                                                                contraventionProvider
                                                                    .contravention!
                                                                    .type)
                                                        .title,
                                                    previewImage: true,
                                                    onDelete: (file) {
                                                      return true;
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            title: e.title,
                                            image: e.image != null
                                                ? File(e.image!.path)
                                                : null,
                                            state: e.id ==
                                                printIssue
                                                    .findIssueNoImage(
                                                        typePCN:
                                                            contraventionProvider
                                                                .contravention!
                                                                .type)
                                                    .id,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }),
                              ],
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
      ),
    );
  }
}

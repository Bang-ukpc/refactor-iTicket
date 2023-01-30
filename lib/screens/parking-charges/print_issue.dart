import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/screens/parking-charges/preview_photo.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/take_photo_item.dart';
import 'package:provider/provider.dart';

class PrintIssue extends StatefulWidget {
  static const routeName = '/print-issue';
  const PrintIssue({super.key});

  @override
  State<PrintIssue> createState() => _PrintIssueState();
}

class _PrintIssueState extends State<PrintIssue> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final printIssue = Provider.of<PrintIssueProviders>(context);
    final contravention =
        ModalRoute.of(context)!.settings.arguments as Contravention;

    log('Print issue');

    void takeAPhoto() async {
      await printIssue.getIdIssue(printIssue.findIssueNoImage().id);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraPicker(
            titleCamera: printIssue.findIssueNoImage().title,
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
      bool check = false;
      showCircularProgressIndicator(context: context);
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        try {
          if (printIssue.data.isNotEmpty) {
            for (int i = 0; i < printIssue.data.length; i++) {
              if (printIssue.data[i].image != null) {
                await contraventionController.uploadContraventionImage(
                  ContraventionCreatePhoto(
                    contraventionReference: contravention.reference ?? '',
                    originalFileName:
                        printIssue.data[i].image!.path.split('/').last,
                    capturedDateTime: DateTime.now(),
                    filePath: printIssue.data[i].image!.path,
                  ),
                );
              }
              if (i == printIssue.data.length - 1) {
                check = true;
              }
            }
          }
          if (check == true) {
            printIssue.resetData();
            if (!mounted) return;
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed(ParkingChargeList.routeName);
          }
        } on DioError catch (error) {
          if (!mounted) return;
          if (error.type == DioErrorType.other) {
            Navigator.of(context).pop();
            CherryToast.error(
              toastDuration: const Duration(seconds: 3),
              title: Text(
                error.message.length > Constant.errorTypeOther
                    ? 'Something went wrong, please try again'
                    : error.message,
                style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);
            return;
          }
          Navigator.of(context).pop();
          CherryToast.error(
            displayCloseButton: false,
            title: Text(
              error.response!.data['message'].toString().length >
                      Constant.errorMaxLength
                  ? 'Internal server error'
                  : error.response!.data['message'],
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
      } else {
        final String? contraventionPhotoData =
            await SharedPreferencesHelper.getStringValue(
                'contraventionPhotoDataLocal');
        final String? contraventionList =
            await SharedPreferencesHelper.getStringValue(
                'contraventionDataLocal');

        if (contraventionPhotoData == null) {
          List<String> newPhotoData = [];
          List<ContraventionPhotos> contraventionImageList = [];
          if (printIssue.data.isNotEmpty) {
            for (int i = 0; i < printIssue.data.length; i++) {
              final String encodedData = json.encode(ContraventionCreatePhoto(
                contraventionReference: contravention.reference ?? '',
                originalFileName:
                    printIssue.data[i].image!.path.split('/').last,
                capturedDateTime: DateTime.now(),
                filePath: printIssue.data[i].image!.path,
              ).toJson());
              newPhotoData.add(encodedData);

              contraventionImageList.add(ContraventionPhotos(
                blobName: printIssue.data[i].image!.path,
                contraventionId: contravention.id,
              ));
            }

            if (contraventionList != null) {
              final contraventions =
                  json.decode(contraventionList) as Map<String, dynamic>;
              Pagination fromJsonContravention =
                  Pagination.fromJson(contraventions);
              var position = fromJsonContravention.rows
                  .indexWhere((i) => i['Id'] == contravention.id);
              if (position != -1) {
                var encodedListImage =
                    contraventionImageList.map((e) => e.toJson());
                fromJsonContravention.rows[position]['ContraventionPhotos'] =
                    List.from(fromJsonContravention.rows[position]
                        ['ContraventionPhotos'])
                      ..addAll(encodedListImage);
              }
              final String encodedDataList =
                  json.encode(Pagination.toJson(fromJsonContravention));
              SharedPreferencesHelper.setStringValue(
                  'contraventionDataLocal', encodedDataList);
            }
          }
          final encodedNewData = json.encode(newPhotoData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        } else {
          final createdData =
              json.decode(contraventionPhotoData) as List<dynamic>;
          List<ContraventionPhotos> contraventionImageList = [];
          if (printIssue.data.isNotEmpty) {
            for (int i = 0; i < printIssue.data.length; i++) {
              if (printIssue.data[i].image != null) {
                final String encodedData = json.encode(ContraventionCreatePhoto(
                  contraventionReference: contravention.reference ?? '',
                  originalFileName:
                      printIssue.data[i].image!.path.split('/').last,
                  capturedDateTime: DateTime.now(),
                  filePath: printIssue.data[i].image!.path,
                ).toJson());
                createdData.add(encodedData);

                contraventionImageList.add(ContraventionPhotos(
                  blobName: printIssue.data[i].image!.path,
                  contraventionId: contravention.id,
                ));
              }
            }

            if (contraventionList != null) {
              final contraventions =
                  json.decode(contraventionList) as Map<String, dynamic>;
              Pagination fromJsonContravention =
                  Pagination.fromJson(contraventions);
              var position = fromJsonContravention.rows
                  .indexWhere((i) => i['Id'] == contravention.id);
              if (position != -1) {
                var encodedListImage =
                    contraventionImageList.map((e) => e.toJson());
                fromJsonContravention.rows[position]['ContraventionPhotos'] =
                    List.from(fromJsonContravention.rows[position]
                        ['ContraventionPhotos'])
                      ..addAll(encodedListImage);
              }
              final String encodedDataList =
                  json.encode(Pagination.toJson(fromJsonContravention));
              SharedPreferencesHelper.setStringValue(
                  'contraventionDataLocal', encodedDataList);
            }
          }
          final encodedNewData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        }
        printIssue.resetData();
        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(ParkingChargeList.routeName);
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          drawer: const MyDrawer(),
          bottomNavigationBar: BottomSheet2(padding: 5, buttonList: [
            BottomNavyBarItem(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AbortScreen.routeName,
                  arguments: contravention,
                );
              },
              icon: SvgPicture.asset(
                'assets/svg/IconAbort.svg',
                color: Colors.white,
              ),
              label: 'Abort',
            ),
            if (!(printIssue.findIssueNoImage().id ==
                printIssue.data.length + 1))
              BottomNavyBarItem(
                onPressed: takeAPhoto,
                icon: SvgPicture.asset(
                  'assets/svg/IconCamera.svg',
                  width: 17,
                  color: Colors.white,
                ),
                label: 'Take a photo',
              ),
            if (printIssue.findIssueNoImage().id == printIssue.data.length + 1)
              BottomNavyBarItem(
                onPressed: () =>
                    Navigator.of(context).pushNamed(PreviewPhoto.routeName),
                icon: SvgPicture.asset(
                  'assets/svg/IconPreview.svg',
                  color: Colors.white,
                ),
                label: 'Preview all',
              ),
            BottomNavyBarItem(
              onPressed: () {
                if (printIssue.findIssueNoImage().title != 'null' &&
                    printIssue.checkIssueHasPhotoRequire() == false) {
                  showMyDialog();
                } else {
                  onCompleteTakePhotos();
                }
              },
              icon: SvgPicture.asset(
                'assets/svg/IconComplete2.svg',
              ),
              label: 'Complete',
            ),
          ]),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: ColorTheme.darkPrimary,
                      padding: const EdgeInsets.all(10),
                      child: Center(
                          child: Text(
                        "Take photos",
                        style: CustomTextStyle.h4.copyWith(color: Colors.white),
                      )),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  "Please take required photos as below:",
                                  style: CustomTextStyle.h5.copyWith(
                                    color: ColorTheme.grey600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Consumer<PrintIssueProviders>(
                                    builder: (_, value, __) {
                                  return Column(
                                    children: value.data
                                        .map((e) => TakePhotoItem(
                                              func: () async {
                                                await printIssue.getIdIssue(
                                                    printIssue
                                                        .findIssueNoImage()
                                                        .id);
                                                await Navigator.of(context)
                                                    .push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CameraPicker(
                                                      titleCamera: printIssue
                                                          .findIssueNoImage()
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
                                                      .findIssueNoImage()
                                                      .id,
                                            ))
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

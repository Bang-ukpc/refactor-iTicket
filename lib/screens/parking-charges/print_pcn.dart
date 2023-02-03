import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_info.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

import '../../widgets/parking-charge/detail_parking_common2.dart';

class PrintPCN extends StatefulWidget {
  static const routeName = '/print-pcn';
  const PrintPCN({super.key});

  @override
  State<PrintPCN> createState() => _PrintPCNState();
}

class _PrintPCNState extends State<PrintPCN> {
  @override
  Widget build(BuildContext context) {
    final contraventionProvider = Provider.of<ContraventionProvider>(context);
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    var args = contraventionProvider.contravention;
    final printIssue = Provider.of<PrintIssueProviders>(context);

    int randomReference = (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
    final contraventionCreate = ContraventionCreateWardenCommand(
      ZoneId: args?.zoneId ?? 0,
      ContraventionReference: args?.reference ?? '$randomReference',
      Plate: args?.plate ?? "",
      VehicleMake: contraventionProvider.getMakeNullProvider ?? "",
      VehicleColour: contraventionProvider.getColorNullProvider ?? "",
      ContraventionReasonCode: args?.reason?.code ?? "",
      EventDateTime: DateTime.now(),
      FirstObservedDateTime:
          args?.contraventionDetailsWarden?.FirstObserved ?? DateTime.now(),
      WardenId: args?.contraventionDetailsWarden?.WardenId ?? 0,
      Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      WardenComments: args!.contraventionEvents!.isNotEmpty
          ? args.contraventionEvents!
              .map((item) => item.detail)
              .toString()
              .replaceAll('(', '')
              .replaceAll(')', '')
          : '',
      BadgeNumber: 'test',
      LocationAccuracy: 0, // missing
      TypePCN: args.type,
    );

    Future<void> issuePCN() async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      final wardenEventIssuePCN = WardenEvent(
        type: TypeWardenEvent.IssuePCN.index,
        detail:
            '{"TicketNumber": "${contraventionCreate.ContraventionReference}"}',
        latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        wardenId: wardensProvider.wardens?.Id ?? 0,
        zoneId: locationProvider.zone?.Id ?? 0,
        locationId: locationProvider.location?.Id ?? 0,
        rotaTimeFrom: locationProvider.rotaShift?.timeFrom,
        rotaTimeTo: locationProvider.rotaShift?.timeTo,
      );

      Contravention? contravention;
      bool check = false;

      if (!mounted) return;

      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        try {
          await contraventionController
              .createPCN(contraventionCreate)
              .then((value) {
            contravention = value;
          });
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
                style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);
            return;
          }
          Navigator.of(context).pop();
          CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            displayCloseButton: true,
            title: Text(
              (error.response?.data['message'].toString().length ?? 0) >
                      Constant.errorMaxLength
                  ? 'Internal server error'
                  : error.response?.data['message'],
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }

        if (contravention != null) {
          for (int i = 0; i < args.contraventionPhotos!.length; i++) {
            try {
              await contraventionController.uploadContraventionImage(
                ContraventionCreatePhoto(
                  contraventionReference: contravention?.reference ?? '',
                  originalFileName:
                      args.contraventionPhotos![i].blobName!.split('/').last,
                  capturedDateTime: DateTime.now(),
                  filePath: args.contraventionPhotos![i].blobName as String,
                ),
              );
            } on DioError catch (error) {
              if (error.type == DioErrorType.other) {
                throw Exception("Something went wrong");
              }
              throw Exception(error.message);
            }

            if (i == args.contraventionPhotos!.length - 1) {
              check = true;
            }
          }
        }

        if (contravention != null && check == true) {
          try {
            await userController
                .createWardenEvent(wardenEventIssuePCN)
                .then((value) {
              contraventionProvider.clearContraventionData();
              printIssue.resetData();
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(ParkingChargeInfo.routeName,
                  arguments: contravention);
              CherryToast.success(
                displayCloseButton: false,
                title: Text(
                  'The PCN has been created successfully',
                  style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
                ),
                toastPosition: Position.bottom,
                borderRadius: 5,
              ).show(context);
            });
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
                  style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
                ),
                toastPosition: Position.bottom,
                borderRadius: 5,
              ).show(context);
              return;
            }
            Navigator.of(context).pop();
            CherryToast.error(
              toastDuration: const Duration(seconds: 3),
              displayCloseButton: true,
              title: Text(
                (error.response?.data['message'].toString().length ?? 0) >
                        Constant.errorMaxLength
                    ? 'Internal server error'
                    : error.response?.data['message'],
                style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);
            return;
          }
        }
      } else {
        int randomNumber =
            (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
        contraventionCreate.Id = randomNumber;
        final String encodedPhysicalPCNData = json.encode(
            ContraventionCreateWardenCommand.toJson(contraventionCreate));
        final String? issuePCNData =
            await SharedPreferencesHelper.getStringValue('issuePCNDataLocal');
        if (issuePCNData == null) {
          List<String> newData = [];
          newData.add(encodedPhysicalPCNData);
          final encodedNewData = json.encode(newData);
          SharedPreferencesHelper.setStringValue(
              'issuePCNDataLocal', encodedNewData);
        } else {
          final createdData = json.decode(issuePCNData) as List<dynamic>;
          createdData.add(encodedPhysicalPCNData);
          final encodedCreatedData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'issuePCNDataLocal', encodedCreatedData);
        }

        final String? contraventionPhotoData =
            await SharedPreferencesHelper.getStringValue(
                'contraventionPhotoDataLocal');
        if (contraventionPhotoData == null) {
          List<String> newPhotoData = [];
          for (int i = 0; i < args.contraventionPhotos!.length; i++) {
            final String encodedData = json.encode(ContraventionCreatePhoto(
              contraventionReference:
                  contraventionCreate.ContraventionReference,
              originalFileName:
                  args.contraventionPhotos![i].blobName!.split('/').last,
              capturedDateTime: DateTime.now(),
              filePath: args.contraventionPhotos![i].blobName as String,
            ).toJson());
            newPhotoData.add(encodedData);
          }
          final encodedNewData = json.encode(newPhotoData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        } else {
          final createdData =
              json.decode(contraventionPhotoData) as List<dynamic>;
          for (int i = 0; i < args.contraventionPhotos!.length; i++) {
            final String encodedData = json.encode(ContraventionCreatePhoto(
              contraventionReference:
                  contraventionCreate.ContraventionReference,
              originalFileName:
                  args.contraventionPhotos![i].blobName!.split('/').last,
              capturedDateTime: DateTime.now(),
              filePath: args.contraventionPhotos![i].blobName as String,
            ).toJson());
            createdData.add(encodedData);
          }
          final encodedNewData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        }

        final String? contraventionList =
            await SharedPreferencesHelper.getStringValue(
                'contraventionDataLocal');

        if (contraventionList == null) {
          List<dynamic> newData = [];
          newData.add(Contravention.toJson(args));
          var dataFormat = Pagination(
            page: 1,
            pageSize: 1000,
            total: newData.length,
            totalPages: 1,
            rows: newData,
          );
          final String encodedNewData =
              json.encode(Pagination.toJson(dataFormat));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedNewData);
        } else {
          final createdData =
              json.decode(contraventionList) as Map<String, dynamic>;
          Pagination fromJsonContravention = Pagination.fromJson(createdData);
          fromJsonContravention.rows.add(Contravention.toJson(args));
          final String encodedCreatedData =
              json.encode(Pagination.toJson(fromJsonContravention));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedCreatedData);
        }

        var contraventionDataFake = contraventionProvider.contravention;

        await userController
            .createWardenEvent(wardenEventIssuePCN)
            .then((value) {
          contraventionProvider.clearContraventionData();
          printIssue.resetData();
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(ParkingChargeInfo.routeName,
              arguments: contraventionDataFake);
          CherryToast.success(
            displayCloseButton: false,
            title: Text(
              'The PCN has been created successfully',
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        });
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        drawer: const MyDrawer(),
        bottomNavigationBar: Consumer<Locations>(
          builder: (context, locations, child) => BottomSheet2(
            buttonList: [
              BottomNavyBarItem(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AbortScreen.routeName,
                  );
                },
                icon: SvgPicture.asset(
                  'assets/svg/IconAbort.svg',
                  color: ColorTheme.textPrimary,
                ),
                label: 'Abort',
              ),
              BottomNavyBarItem(
                onPressed: () async {
                  showCircularProgressIndicator(context: context);
                  issuePCN();
                },
                icon: SvgPicture.asset(
                  'assets/svg/IconComplete2.svg',
                ),
                label: 'Complete',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: DetailParkingCommon2(
            contravention: args,
            imagePreviewStatus: true,
          ),
        ),
      ),
    );
  }
}

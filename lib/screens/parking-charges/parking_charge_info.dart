import 'dart:convert';
import 'dart:developer';

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
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/parking-charge/detail_parking_common.dart';
import 'package:provider/provider.dart';

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
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);

    log('Parking charge info');

    Future<void> createVirtualTicket() async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
      final virtualTicket = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference: '$randomReference',
        Plate: args.plate as String,
        VehicleMake: args.make as String,
        VehicleColour: args.colour as String,
        ContraventionReasonCode: args.reason!.code as String,
        EventDateTime: DateTime.now(),
        FirstObservedDateTime: args.eventDateTime as DateTime,
        WardenId: wardensProvider.wardens?.Id ?? 0,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        WardenComments: args.contraventionEvents!
            .map((item) => item.detail)
            .toString()
            .replaceAll('(', '')
            .replaceAll(')', ''),
        BadgeNumber: 'test',
        LocationAccuracy: 0, // missing
        TypePCN: TypePCN.Virtual.index,
      );

      final wardenEventIssuePCN = WardenEvent(
        type: TypeWardenEvent.IssuePCN.index,
        detail: '{"TicketNumber": "${virtualTicket.ContraventionReference}"}',
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
      showCircularProgressIndicator(context: context);

      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        try {
          await contraventionController.createPCN(virtualTicket).then((value) {
            contravention = value;
          });
          if (contravention != null) {
            for (int i = 0; i < args.contraventionPhotos!.length; i++) {
              await contraventionController.uploadContraventionImage(
                ContraventionCreatePhoto(
                  contraventionReference: contravention?.reference ?? '',
                  originalFileName:
                      args.contraventionPhotos![i].blobName!.split('/').last,
                  capturedDateTime: DateTime.now(),
                  filePath: args.contraventionPhotos![i].blobName as String,
                ),
              );
              if (i == args.contraventionPhotos!.length - 1) {
                check = true;
              }
            }
          }
          if (contravention != null && check == true) {
            await userController
                .createWardenEvent(wardenEventIssuePCN)
                .then((value) {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(ParkingChargeList.routeName);
            });
          }
        } on DioError catch (error) {
          if (!mounted) return;
          log("log ${error.type.toString()}");
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
            toastDuration: const Duration(seconds: 3),
            displayCloseButton: true,
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
        int randomNumber =
            (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
        virtualTicket.Id = randomNumber;
        final String encodedPhysicalPCNData =
            json.encode(ContraventionCreateWardenCommand.toJson(virtualTicket));
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
              contraventionReference: virtualTicket.ContraventionReference,
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
              contraventionReference: randomNumber.toString(),
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

        await userController
            .createWardenEvent(wardenEventIssuePCN)
            .then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(ParkingChargeList.routeName);
        });
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                  color: Colors.white,
                ),
                label: 'Abort',
              ),
              BottomNavyBarItem(
                onPressed: () {
                  createVirtualTicket();
                },
                icon: SvgPicture.asset(
                  'assets/svg/IconComplete.svg',
                ),
                label: 'Complete',
              ),
            ],
          ),
        ),
        appBar: MyAppBar(
          title: "View PCN",
          automaticallyImplyLeading: false,
          isOpenDrawer: false,
          isOnlyTitle: true,
          onRedirect: () {
            Navigator.of(context).popAndPushNamed(ParkingChargeList.routeName);
          },
        ),
        drawer: const MyDrawer(),
        body: DetailParkingCommon(
          contravention: args,
          imagePreviewStatus: true,
        ),
      ),
    );
  }
}

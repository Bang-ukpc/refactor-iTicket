import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/evidence_photo_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/local/issued_pcn_local_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth.dart';

Future<void> showLoading({
  required int firstSeenLength,
  required gracePeriodLength,
  required pcnLength,
}) async {
  await showDialog(
    context: NavigationService.navigatorKey.currentContext as BuildContext,
    barrierDismissible: false,
    barrierColor: ColorTheme.mask,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: SizedBox(
          width: MediaQuery.of(NavigationService.navigatorKey.currentContext
                      as BuildContext)
                  .size
                  .width *
              0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: ColorTheme.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Synchronizing data with the server:',
                style: CustomTextStyle.h4.copyWith(
                  fontFamily: 'Lato',
                  decoration: TextDecoration.none,
                  color: ColorTheme.white,
                  overflow: TextOverflow.clip,
                ),
                textAlign: TextAlign.center,
              ),
              if (firstSeenLength > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '$firstSeenLength first seen sent to the server',
                      style: CustomTextStyle.h4.copyWith(
                        fontFamily: 'Lato',
                        decoration: TextDecoration.none,
                        color: ColorTheme.white,
                        overflow: TextOverflow.clip,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (gracePeriodLength > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '$gracePeriodLength grace period sent to the server',
                      style: CustomTextStyle.h4.copyWith(
                        fontFamily: 'Lato',
                        decoration: TextDecoration.none,
                        color: ColorTheme.white,
                        overflow: TextOverflow.clip,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              if (pcnLength > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '$pcnLength PCN(s) sent to the server',
                      style: CustomTextStyle.h4.copyWith(
                        fontFamily: 'Lato',
                        decoration: TextDecoration.none,
                        color: ColorTheme.white,
                        overflow: TextOverflow.clip,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> isAuth() async {
  String? token =
      await SharedPreferencesHelper.getStringValue(PreferencesKeys.accessToken);
  return token != null ? true : false;
}

class NetworkLayout extends StatefulWidget {
  final Widget myWidget;
  const NetworkLayout({required this.myWidget, super.key});

  @override
  State<NetworkLayout> createState() => _NetworkLayoutState();
}

class _NetworkLayoutState extends State<NetworkLayout> {
  final Connectivity _connectivity = Connectivity();

  Future<bool> vehicleInfoDataSynch() async {
    final String? dataUpsert = await SharedPreferencesHelper.getStringValue(
        'vehicleInfoUpsertDataLocal');
    if (dataUpsert != null) {
      final vehicleInfoUpsertData = json.decode(dataUpsert) as List<dynamic>;
      List<VehicleInformation> vehicleInfoList = vehicleInfoUpsertData
          .map((i) => VehicleInformation.fromJson(json.decode(i)))
          .toList();
      for (int i = 0; i < vehicleInfoList.length; i++) {
        for (int j = 0; j < vehicleInfoList[i].EvidencePhotos!.length; j++) {
          try {
            await evidencePhotoController
                .uploadImage(
                    filePath: vehicleInfoList[i].EvidencePhotos![j].BlobName,
                    capturedDateTime: vehicleInfoList[i].Created)
                .then((value) {
              vehicleInfoList[i].EvidencePhotos![j] =
                  EvidencePhoto(BlobName: value['blobName']);
            });
          } on DioError catch (e) {
            print('evidencePhotoController: $e');
            // throw Exception(e.message);
          }
        }
        try {
          if (vehicleInfoList[i].Id != null && vehicleInfoList[i].Id! < 0) {
            vehicleInfoList[i].Id = null;
          }
          await vehicleInfoController.upsertVehicleInfo(vehicleInfoList[i]);
        } on DioError catch (e) {
          print('upsertVehicleInfo: $e');
          // throw Exception(e.message);
        }
      }
      SharedPreferencesHelper.removeStringValue('vehicleInfoUpsertDataLocal');
      return true;
    } else {
      return true;
    }
  }

  Future<bool> parkingChargeDataSynch() async {
    final String? issuePCNData =
        await SharedPreferencesHelper.getStringValue('issuePCNDataLocal');
    final String? contraventionPhotoData =
        await SharedPreferencesHelper.getStringValue(
            'contraventionPhotoDataLocal');

    if (issuePCNData != null) {
      var decodedData = json.decode(issuePCNData) as List<dynamic>;
      List<ContraventionCreateWardenCommand> physicalPCNList = decodedData
          .map((e) => ContraventionCreateWardenCommand.fromJson(json.decode(e)))
          .toList();
      List<ContraventionCreatePhoto> contraventionCreatePhoto = [];

      if (contraventionPhotoData != null) {
        var contraventionPhotoDecoded =
            json.decode(contraventionPhotoData) as List<dynamic>;
        contraventionCreatePhoto = contraventionPhotoDecoded
            .map((e) => ContraventionCreatePhoto.fromJson(json.decode(e)))
            .toList();
      }

      for (int i = 0; i < physicalPCNList.length; i++) {
        try {
          await contraventionController.createPCN(physicalPCNList[i]);
        } on DioError catch (e) {
          print('createPCN: $e');
          // throw Exception(e.message);
        }
      }
      for (int i = 0; i < contraventionCreatePhoto.length; i++) {
        try {
          await contraventionController
              .uploadContraventionImage(contraventionCreatePhoto[i]);
        } on DioError catch (e) {
          print('uploadContraventionImage: $e');
          // throw Exception(e.message);
        }
      }

      SharedPreferencesHelper.removeStringValue('issuePCNDataLocal');
      SharedPreferencesHelper.removeStringValue('contraventionPhotoDataLocal');
      return true;
    } else {
      return true;
    }
  }

  Future<bool> wardenEventDataSync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final String? dataWardenEvent =
        await SharedPreferencesHelper.getStringValue('wardenEventDataLocal');
    final String? dataWardenEventTrackGPS =
        await SharedPreferencesHelper.getStringValue(
            'wardenEventCheckGPSDataLocal');

    if (dataWardenEvent != null) {
      var decodedWardenEventData =
          json.decode(dataWardenEvent) as List<dynamic>;

      if (dataWardenEventTrackGPS != null) {
        var decodedWardenEventTrackGPSData =
            json.decode(dataWardenEventTrackGPS) as List<dynamic>;
        decodedWardenEventData = List.from(decodedWardenEventData)
          ..addAll(decodedWardenEventTrackGPSData);
        SharedPreferencesHelper.removeStringValue(
            'wardenEventCheckGPSDataLocal');
      }

      log(decodedWardenEventData.toString());

      List<WardenEvent> wardenEventList = decodedWardenEventData
          .map((i) => WardenEvent.fromJson(json.decode(i)))
          .toList();
      wardenEventList.sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
      for (int i = 0; i < wardenEventList.length; i++) {
        wardenEventList[i].Id = 0;
        try {
          await userController.createWardenEvent(wardenEventList[i]);
        } on DioError catch (e) {
          print('createWardenEvent: $e');
          // throw Exception(e.message);
        }
      }
      SharedPreferencesHelper.removeStringValue('wardenEventDataLocal');
      return true;
    } else {
      if (dataWardenEventTrackGPS != null) {
        var decodedWardenEventTrackGPSData =
            json.decode(dataWardenEventTrackGPS) as List<dynamic>;
        List<WardenEvent> wardenEventList = decodedWardenEventTrackGPSData
            .map((i) => WardenEvent.fromJson(json.decode(i)))
            .toList();
        wardenEventList.sort((i1, i2) => i1.Created!.compareTo(i2.Created!));
        for (int i = 0; i < wardenEventList.length; i++) {
          wardenEventList[i].Id = 0;
          try {
            await userController.createWardenEvent(wardenEventList[i]);
          } on DioError catch (e) {
            print('createWardenEvent: $e');
            // throw Exception(e.message);
          }
        }
        SharedPreferencesHelper.removeStringValue(
            'wardenEventCheckGPSDataLocal');
      }
      return true;
    }
  }

  void dataSynch() async {
    // bool vehicleInfoSynchStatus = false;
    // bool issuePCNSynchStatus = false;
    // bool wardenEventSyncStatus = false;
    // await vehicleInfoDataSynch().then((value) {
    //   vehicleInfoSynchStatus = value;
    // });
    // await parkingChargeDataSynch().then((value) {
    //   issuePCNSynchStatus = value;
    // });
    // await wardenEventDataSync().then((value) {
    //   wardenEventSyncStatus = value;
    // });
    // if (vehicleInfoSynchStatus == true &&
    //     issuePCNSynchStatus == true &&
    //     wardenEventSyncStatus == true) {
    //   await Future.delayed(const Duration(seconds: 1), () {
    //     NavigationService.navigatorKey.currentState!.pop();
    //   });
    // }
    await vehicleInfoDataSynch();
    // await parkingChargeDataSynch();
    await issuedPcnLocalService.syncAll();
    await wardenEventDataSync();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
      bool checkIsAuth = await isAuth();
      if (checkIsAuth == true) {
        var firstSeenLength = 0;
        var gracePeriodLength = 0;
        var pcnLength = 0;

        final String? dataUpsert = await SharedPreferencesHelper.getStringValue(
            'vehicleInfoUpsertDataLocal');
        final String? issuePCNData =
            await SharedPreferencesHelper.getStringValue('issuePCNDataLocal');

        if (dataUpsert != null) {
          final vehicleInfoUpsertData =
              json.decode(dataUpsert) as List<dynamic>;
          List<VehicleInformation> vehicleInfoList = vehicleInfoUpsertData
              .map((i) => VehicleInformation.fromJson(json.decode(i)))
              .toList();

          var firstSeenList = vehicleInfoList
              .where((e) => e.Type == VehicleInformationType.FIRST_SEEN.index)
              .toList();
          var gracePeriodList = vehicleInfoList
              .where((e) => e.Type == VehicleInformationType.GRACE_PERIOD.index)
              .toList();

          firstSeenLength = firstSeenList.length;
          gracePeriodLength = gracePeriodList.length;
        }

        if (issuePCNData != null) {
          var decodedData = json.decode(issuePCNData) as List<dynamic>;
          pcnLength = decodedData.length;
        }

        showLoading(
            firstSeenLength: firstSeenLength,
            gracePeriodLength: gracePeriodLength,
            pcnLength: pcnLength);
        dataSynch();

        await Future.delayed(const Duration(seconds: 3), () {
          NavigationService.navigatorKey.currentState!.pop();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final authProvider = Provider.of<Auth>(context, listen: false);
      bool checkIsAuth = await authProvider.isAuth();
      if (checkIsAuth == true) {
        Timer.periodic(const Duration(seconds: 30), (timer) async {
          await currentLocationPosition.getCurrentLocation();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.myWidget,
    );
  }
}

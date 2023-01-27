import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/controllers/abort_controller.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/evidence_photo_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showLoading() async {
  await showDialog(
    context: NavigationService.navigatorKey.currentContext as BuildContext,
    barrierDismissible: false,
    barrierColor: ColorTheme.mask,
    builder: (_) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            width: MediaQuery.of(NavigationService.navigatorKey.currentContext
                        as BuildContext)
                    .size
                    .width *
                0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 250),
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
                Expanded(
                  child: Text(
                    'Synchronizing data to the server',
                    style: CustomTextStyle.h4.copyWith(
                      decoration: TextDecoration.none,
                      color: ColorTheme.white,
                      overflow: TextOverflow.clip,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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
                .uploadImage(vehicleInfoList[i].EvidencePhotos![j].BlobName)
                .then((value) {
              vehicleInfoList[i].EvidencePhotos![j] =
                  EvidencePhoto(BlobName: value['blobName']);
            });
          } catch (e) {
            print('evidencePhotoController: $e');
            return true;
          }
        }
        try {
          if (vehicleInfoList[i].Id != null && vehicleInfoList[i].Id! < 0) {
            vehicleInfoList[i].Id = null;
          }
          await vehicleInfoController.upsertVehicleInfo(vehicleInfoList[i]);
        } catch (e) {
          print('upsertVehicleInfo: $e');
          return true;
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
    final String? dataAbortPCN =
        await SharedPreferencesHelper.getStringValue('abortPCNDataLocal');

    if (issuePCNData != null) {
      var decodedData = json.decode(issuePCNData) as List<dynamic>;
      List<ContraventionCreateWardenCommand> physicalPCNList = decodedData
          .map((e) => ContraventionCreateWardenCommand.fromJson(json.decode(e)))
          .toList();
      List<ContraventionCreatePhoto> contraventionCreatePhoto = [];
      List<AbortPCN> abortPCN = [];

      if (contraventionPhotoData != null) {
        var contraventionPhotoDecoded =
            json.decode(contraventionPhotoData) as List<dynamic>;
        contraventionCreatePhoto = contraventionPhotoDecoded
            .map((e) => ContraventionCreatePhoto.fromJson(json.decode(e)))
            .toList();
      }

      if (dataAbortPCN != null) {
        var abortDataDecoded = json.decode(dataAbortPCN) as List<dynamic>;
        abortPCN = abortDataDecoded
            .map((e) => AbortPCN.fromJson(json.decode(e)))
            .toList();
      }

      for (int i = 0; i < physicalPCNList.length; i++) {
        try {
          await contraventionController
              .createPCN(physicalPCNList[i])
              .then((contravention) async {
            print(contravention.id);
            for (int j = 0; j < abortPCN.length; j++) {
              if (physicalPCNList[i].Id == abortPCN[j].contraventionId) {
                abortPCN[j].contraventionId = contravention.id ?? 0;
                try {
                  await abortController.abortPCN(abortPCN[j]);
                } catch (e) {
                  print('abortPCN: $e');
                  break;
                }
              }
            }
          });
        } catch (e) {
          print('createPCN: $e');
          return true;
        }
      }
      for (int i = 0; i < contraventionCreatePhoto.length; i++) {
        try {
          await contraventionController
              .uploadContraventionImage(contraventionCreatePhoto[i]);
        } catch (e) {
          print('uploadContraventionImage: $e');
          return true;
        }
      }

      SharedPreferencesHelper.removeStringValue('issuePCNDataLocal');
      SharedPreferencesHelper.removeStringValue('contraventionPhotoDataLocal');
      SharedPreferencesHelper.removeStringValue('abortPCNDataLocal');
      return true;
    } else {
      return true;
    }
  }

  Future<bool> wardenEventDataSync() async {
    final String? dataWardenEvent =
        await SharedPreferencesHelper.getStringValue('wardenEventDataLocal');
    final String? dataWardenEventTrackGPS =
        await SharedPreferencesHelper.getStringValue(
            'wardenEventCheckGPSDataLocal');

    if (dataWardenEvent != null) {
      var decodedWardenEventData =
          json.decode(dataWardenEvent) as List<dynamic>;
      print(dataWardenEventTrackGPS);

      if (dataWardenEventTrackGPS != null) {
        log('dataWardenEventTrackGPS != null');
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
        } catch (e) {
          print('createWardenEvent: $e');
          return true;
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
          } catch (e) {
            print('createWardenEvent: $e');
            return true;
          }
        }
        SharedPreferencesHelper.removeStringValue(
            'wardenEventCheckGPSDataLocal');
      }
      return true;
    }
  }

  void dataSynch() async {
    bool vehicleInfoSynchStatus = false;
    bool issuePCNSynchStatus = false;
    bool wardenEventSyncStatus = false;
    await vehicleInfoDataSynch().then((value) {
      vehicleInfoSynchStatus = value;
    });
    await parkingChargeDataSynch().then((value) {
      issuePCNSynchStatus = value;
    });
    await wardenEventDataSync().then((value) {
      wardenEventSyncStatus = value;
    });
    if (vehicleInfoSynchStatus == true &&
        issuePCNSynchStatus == true &&
        wardenEventSyncStatus == true) {
      await Future.delayed(const Duration(seconds: 1), () {
        NavigationService.navigatorKey.currentState!.pop();
      });
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
      bool checkIsAuth = await isAuth();
      if (checkIsAuth == true) {
        showLoading();
        dataSynch();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.myWidget,
    );
  }
}

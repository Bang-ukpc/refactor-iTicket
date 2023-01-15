import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/controllers/evidence_photo_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
      print(vehicleInfoUpsertData);
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
          print('vehicleInfoController: $e');
          return true;
        }
      }
      SharedPreferencesHelper.removeStringValue('vehicleInfoUpsertDataLocal');
      return true;
    } else {
      return true;
    }
  }

  void dataSynch() async {
    bool vehicleInfoSynchStatus = false;
    await vehicleInfoDataSynch().then((value) {
      vehicleInfoSynchStatus = value;
    });
    if (vehicleInfoSynchStatus == true) {
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

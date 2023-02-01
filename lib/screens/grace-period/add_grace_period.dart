import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/button_scan.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/configs/scan-plate/anyline_service.dart';
import 'package:iWarden/configs/scan-plate/result.dart';
import 'package:iWarden/configs/scan-plate/scan_modes.dart';
import 'package:iWarden/controllers/evidence_photo_controller.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/grace-period/index.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

class AddGracePeriod extends StatefulWidget {
  static const routeName = '/add-grace-period';
  const AddGracePeriod({super.key});

  @override
  State<AddGracePeriod> createState() => _AddGracePeriodState();
}

class _AddGracePeriodState extends State<AddGracePeriod> {
  late AnylineService _anylineService;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _vrnController = TextEditingController();
  final _bayNumberController = TextEditingController();
  List<File> arrayImage = [];
  List<EvidencePhoto> evidencePhotoList = [];

  Future<void> getLocationList(Locations locations, int wardenId) async {
    ListLocationOfTheDayByWardenIdProps listLocationOfTheDayByWardenIdProps =
        ListLocationOfTheDayByWardenIdProps(
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardenId,
    );

    await locationController
        .getAll(listLocationOfTheDayByWardenIdProps)
        .then((value) {
      for (int i = 0; i < value.length; i++) {
        for (int j = 0; j < value.length; j++) {
          if (value[i].locations![j].Id == locations.location!.Id) {
            var zoneSelected = value[i]
                .locations![j]
                .Zones!
                .firstWhereOrNull((e) => e.Id == locations.zone!.Id);
            locations.onSelectedZone(zoneSelected);
            return;
          }
        }
      }
    }).catchError((err) {
      print(err);
    });
  }

  @override
  void initState() {
    super.initState();
    _anylineService = AnylineServiceImpl();
  }

  Future<void> scan(ScanMode mode) async {
    try {
      Result? result = await _anylineService.scan(mode);
      if (result != null) {
        String resultText = result.jsonMap!.values
            .take(2)
            .toString()
            .split(',')[1]
            .replaceAll(RegExp('[^A-Za-z0-9]'), '')
            .replaceAll(' ', '');
        setState(() {
          _vrnController.text = resultText.substring(0, resultText.length);
        });
      }
    } catch (e, s) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          elevation: 0,
          title: const FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              'Error',
            ),
          ),
          content: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              '$e, $s',
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _vrnController.dispose();
    _bayNumberController.dispose();
    arrayImage.clear();
    evidencePhotoList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);

    Future<bool> saveForm() async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      final vehicleInfo = VehicleInformation(
        Id: 0,
        ExpiredAt: DateTime.now().add(
          Duration(
            seconds: locationProvider.expiringTimeGracePeriod,
          ),
        ),
        Plate: _vrnController.text,
        ZoneId: locationProvider.zone!.Id as int,
        LocationId: locationProvider.location!.Id as int,
        BayNumber: _bayNumberController.text,
        Type: VehicleInformationType.GRACE_PERIOD.index,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        CarLeft: false,
        EvidencePhotos: evidencePhotoList,
        Created: DateTime.now(),
        CreatedBy: wardensProvider.wardens?.Id ?? 0,
      );
      final isValid = _formKey.currentState!.validate();
      bool check = false;
      setState(() {
        evidencePhotoList.clear();
      });
      if (arrayImage.isEmpty) {
        if (!mounted) return false;
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'Please take at least 1 picture',
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        return false;
      }
      if (!isValid) {
        return false;
      } else {
        showCircularProgressIndicator(context: context);
      }
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        try {
          await getLocationList(
              locationProvider, wardensProvider.wardens?.Id ?? 0);
          if (arrayImage.isNotEmpty) {
            for (int i = 0; i < arrayImage.length; i++) {
              await evidencePhotoController
                  .uploadImage(arrayImage[i].path)
                  .then((value) {
                evidencePhotoList
                    .add(EvidencePhoto(BlobName: value['blobName']));
              });
            }
          }

          await vehicleInfoController
              .upsertVehicleInfo(vehicleInfo)
              .then((value) {
            if (value != null) {
              check = true;
            }
          });

          if (check == true) {
            if (!mounted) return false;
            Navigator.of(context).pop();
            CherryToast.success(
              displayCloseButton: false,
              title: Text(
                'Grace period added successfully',
                style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);

            setState(() {
              _vrnController.text = '';
              _bayNumberController.text = '';
              arrayImage.clear();
              evidencePhotoList.clear();
            });
          }
        } on DioError catch (error) {
          if (!mounted) return false;
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
            return false;
          }
          Navigator.of(context).pop();
          CherryToast.error(
            displayCloseButton: false,
            title: Text(
              error.response!.data['message'].toString().length >
                      Constant.errorMaxLength
                  ? 'Internal server error'
                  : error.response!.data['message'],
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return false;
        }
      } else {
        int randomNumber =
            (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
        vehicleInfo.Id = randomNumber;
        vehicleInfo.Created = DateTime.now();
        if (arrayImage.isNotEmpty) {
          for (int i = 0; i < arrayImage.length; i++) {
            evidencePhotoList.add(
              EvidencePhoto(
                BlobName: arrayImage[i].path,
                VehicleInformationId: vehicleInfo.Id,
                Created: DateTime.now(),
              ),
            );
          }
        }
        final String encodedData = json.encode(vehicleInfo.toJson());
        final String? vehicleUpsertData =
            await SharedPreferencesHelper.getStringValue(
                'vehicleInfoUpsertDataLocal');
        if (vehicleUpsertData == null) {
          List<String> newData = [];
          newData.add(encodedData);
          final encodedNewData = json.encode(newData);
          SharedPreferencesHelper.setStringValue(
              'vehicleInfoUpsertDataLocal', encodedNewData);
        } else {
          final createdData = json.decode(vehicleUpsertData) as List<dynamic>;
          createdData.add(encodedData);
          final encodedCreatedData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'vehicleInfoUpsertDataLocal', encodedCreatedData);
        }
        if (!mounted) return false;
        Navigator.of(context).pop();
        CherryToast.success(
          displayCloseButton: false,
          title: Text(
            'Grace period added successfully',
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);

        setState(() {
          _vrnController.text = '';
          _bayNumberController.text = '';
          arrayImage.clear();
          evidencePhotoList.clear();
        });
      }

      _formKey.currentState!.save();
      return true;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: "Add consideration period ",
          automaticallyImplyLeading: true,
          onRedirect: () {
            Navigator.of(context).popAndPushNamed(GracePeriodList.routeName);
          },
        ),
        drawer: const MyDrawer(),
        bottomNavigationBar: BottomSheet2(buttonList: [
          BottomNavyBarItem(
            onPressed: () async {
              await saveForm().then((value) {
                if (value == true) {
                  Navigator.of(context)
                      .popAndPushNamed(GracePeriodList.routeName);
                  CherryToast.success(
                    displayCloseButton: false,
                    title: Text(
                      'Grace period added successfully',
                      style: CustomTextStyle.h4
                          .copyWith(color: ColorTheme.success),
                    ),
                    toastPosition: Position.bottom,
                    borderRadius: 5,
                  ).show(context);
                }
              });
            },
            icon: SvgPicture.asset(
              'assets/svg/IconComplete2.svg',
            ),
            label: 'Complete',
          ),
          BottomNavyBarItem(
            onPressed: saveForm,
            icon: SvgPicture.asset(
              'assets/svg/IconSave2.svg',
              width: 20,
              height: 20,
              color: Colors.white,
            ),
            label: 'Save & add',
          ),
        ]),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SingleChildScrollView(
            child: Container(
              margin:
                  const EdgeInsets.only(bottom: ConstSpacing.bottom, top: 20),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 24,
                    ),
                    color: Colors.white,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                flex: 8,
                                child: TextFormField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9]'),
                                    ),
                                  ],
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  controller: _vrnController,
                                  style:
                                      CustomTextStyle.h5.copyWith(fontSize: 16),
                                  decoration: const InputDecoration(
                                    label: LabelRequire(labelText: "VRN"),
                                    hintText: "Enter VRN",
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                      color: ColorTheme.grey400,
                                    ),
                                  ),
                                  validator: ((value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter VRN';
                                    } else {
                                      if (value.length < 2) {
                                        return 'Please enter at least 2 characters';
                                      }
                                      return null;
                                    }
                                  }),
                                  onSaved: (value) {
                                    _vrnController.text = value as String;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                              ),
                              Flexible(
                                flex: 2,
                                child: ButtonScan(
                                  onTap: () {
                                    scan(ScanMode.LicensePlate);
                                  },
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          TextFormField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[^\s]+\b\s?'),
                              ),
                            ],
                            style: CustomTextStyle.h5.copyWith(fontSize: 16),
                            decoration: const InputDecoration(
                              labelText: 'Bay number',
                              hintText: "Enter bay number",
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: ColorTheme.grey400,
                              ),
                            ),
                            controller: _bayNumberController,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  AddImage(
                    isCamera: true,
                    listImage: arrayImage,
                    onAddImage: () async {
                      final results =
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CameraPicker(
                                    initialFiles: arrayImage,
                                    titleCamera: "Take photo of vehicle",
                                    onDelete: (file) {
                                      return true;
                                    },
                                    editImage: true,
                                  )));
                      if (results != null) {
                        setState(() {
                          arrayImage = List.from(results);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

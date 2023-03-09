import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/id_helper.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/parking-charges/alert_check_vrn.dart';
import 'package:iWarden/services/cache/factory/cache_factory.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

import '../../../controllers/index.dart';
import '../../../helpers/check_turn_on_net_work.dart';
import '../../../helpers/my_navigator_observer.dart';
import '../../../models/ContraventionService.dart';

class AddFirstSeenScreen extends StatefulWidget {
  static const routeName = '/add-first-seen';
  const AddFirstSeenScreen({super.key});

  @override
  BaseStatefulState<AddFirstSeenScreen> createState() =>
      _AddFirstSeenScreenState();
}

class _AddFirstSeenScreenState extends BaseStatefulState<AddFirstSeenScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _vrnController = TextEditingController();
  final _bayNumberController = TextEditingController();
  List<File> arrayImage = [];
  List<EvidencePhoto> evidencePhotoList = [];
  late CachedServiceFactory cachedServiceFactory;
  AutovalidateMode validateMode = AutovalidateMode.disabled;
  bool isCheckedPermit = false;

  Future<void> getLocationList(Locations locations) async {
    List<RotaWithLocation> rotas = [];

    try {
      await cachedServiceFactory.rotaWithLocationCachedService.syncFromServer();
      rotas = await cachedServiceFactory.rotaWithLocationCachedService.getAll();
    } catch (e) {
      rotas = await cachedServiceFactory.rotaWithLocationCachedService.getAll();
    }

    for (int i = 0; i < rotas.length; i++) {
      for (int j = 0; j < rotas[i].locations!.length; j++) {
        if (rotas[i].locations![j].Id == locations.location!.Id) {
          locations.onSelectedLocation(rotas[i].locations![j]);
          var zoneSelected = rotas[i]
              .locations![j]
              .Zones!
              .firstWhereOrNull((e) => e.Id == locations.zone!.Id);
          locations.onSelectedZone(zoneSelected);
          return;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final wardensProvider = Provider.of<WardensInfo>(context, listen: false);
    cachedServiceFactory =
        CachedServiceFactory(wardensProvider.wardens?.Id ?? 0);
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
    final wardenProvider = Provider.of<WardensInfo>(context);
    var zoneCachedServiceFactory = locationProvider.zoneCachedServiceFactory;
    Widget itemInfoDialog({required String title, String? value}) {
      return Row(
        children: [
          Text(
            '$title: ',
            style: CustomTextStyle.h5,
          ),
          Text(
            value ?? 'No data',
            style: CustomTextStyle.h5.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    Future<void> showDialogPermitExists(CheckPermit? value) async {
      return showDialog<void>(
        context: context,
        barrierColor: ColorTheme.backdrop,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 0),
              contentPadding: EdgeInsets.zero,
              title: Center(
                  child: Column(
                children: [
                  Text(
                    "Permit exists with in this location",
                    style: CustomTextStyle.h4.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorTheme.danger,
                    ),
                  ),
                  const Divider(),
                ],
              )),
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 8,
                      ),
                      itemInfoDialog(
                          title: "VRN", value: value?.permitInfo?.VRN),
                      const SizedBox(
                        height: 10,
                      ),
                      itemInfoDialog(
                          title: "Bay information",
                          value: value?.permitInfo?.bayNumber),
                      const SizedBox(
                        height: 10,
                      ),
                      itemInfoDialog(
                          title: "Source", value: value?.permitInfo?.source),
                      const SizedBox(
                        height: 10,
                      ),
                      itemInfoDialog(
                          title: "Tenant", value: value?.permitInfo?.tenant),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: ColorTheme.grey300,
                              ),
                              child: Text(
                                "OK",
                                style: CustomTextStyle.h4
                                    .copyWith(color: ColorTheme.textPrimary),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    Future<bool> saveForm() async {
      DateTime now = await timeNTP.get();
      final vehicleInfo = VehicleInformation(
        Id: idHelper.generateId(),
        ExpiredAt: now.add(
          Duration(
            seconds: locationProvider.expiringTimeFirstSeen,
          ),
        ),
        Plate: _vrnController.text,
        ZoneId: locationProvider.zone!.Id as int,
        LocationId: locationProvider.location!.Id as int,
        BayNumber: _bayNumberController.text,
        Type: VehicleInformationType.FIRST_SEEN.index,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        CarLeftAt: null,
        EvidencePhotos: evidencePhotoList,
        Created: now,
        CreatedBy: wardenProvider.wardens?.Id ?? 0,
      );

      final isValid = _formKey.currentState!.validate();

      setState(() {
        evidencePhotoList.clear();
      });
      if (arrayImage.isEmpty) {
        // ignore: use_build_context_synchronously
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
      }

      var isExistsWithOverStaying = await zoneCachedServiceFactory
          .firstSeenCachedService
          .isExistsWithOverStayingInPCNs(
        vrn: vehicleInfo.Plate,
        zoneId: vehicleInfo.ZoneId,
      );
      var isExisted = await zoneCachedServiceFactory.firstSeenCachedService
          .isExisted(vehicleInfo.Plate);

      if (!isExistsWithOverStaying) {
        if (!mounted) return false;
        showAlertCheckVrnExits(context: context, checkAddFirstSeen: true);
        return false;
      }

      if (isExisted) {
        if (!mounted) return false;
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'It is not permitted to issue more than one First seen per VRN.',
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        return false;
      }

      if (!mounted) return false;
      showCircularProgressIndicator(context: context);

      vehicleInfo.EvidencePhotos = arrayImage
          .map(
            (image) => EvidencePhoto(
              Id: idHelper.generateId(),
              BlobName: image.path,
              Created: now,
              VehicleInformationId: vehicleInfo.Id,
            ),
          )
          .toList();
      await getLocationList(locationProvider).then((value) {
        vehicleInfo.ExpiredAt = now.add(
          Duration(
            seconds: locationProvider.expiringTimeFirstSeen,
          ),
        );
      });

      await createdVehicleDataLocalService.create(vehicleInfo);

      if (!mounted) return false;
      Navigator.of(context).pop();
      CherryToast.success(
        displayCloseButton: false,
        title: Text(
          'First seen added successfully',
          style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
        ),
        toastPosition: Position.bottom,
        borderRadius: 5,
      ).show(context);

      _formKey.currentState!.save();
      return true;
    }

    addFirstSeenModeComplete() async {
      await saveForm().then((value) {
        if (value == true) {
          Navigator.of(context)
              .popAndPushNamed(ActiveFirstSeenScreen.routeName);
          CherryToast.success(
            displayCloseButton: false,
            title: Text(
              'First seen added successfully',
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        }
      });
    }

    addFirstSeenModeCompleteAndAdd() async {
      await saveForm().then((value) {
        if (value == true) {
          setState(() {
            _vrnController.text = '';
            _bayNumberController.text = '';
            arrayImage.clear();
            evidencePhotoList.clear();
            validateMode = AutovalidateMode.disabled;
          });
        }
      });
    }

    sendMessageInternalServer(DioError error) {
      Navigator.of(context).pop();
      CherryToast.error(
        displayCloseButton: false,
        title: Text(
          error.message,
          style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
        ),
        toastPosition: Position.bottom,
        borderRadius: 5,
      ).show(context);
      return;
    }

    void showErrorMessage(String error) {
      CherryToast.error(
        displayCloseButton: false,
        title: Text(
          error,
          style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
        ),
        toastPosition: Position.bottom,
        borderRadius: 5,
      ).show(context);
      return;
    }

    bool checkVrnIsValid() {
      if (_vrnController.text.isEmpty) {
        return false;
      } else {
        if (_vrnController.text.length < 2) {
          return false;
        } else if (_vrnController.text.length > 10) {
          return false;
        }
        return true;
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: "Add first seen",
          automaticallyImplyLeading: true,
          onRedirect: () {
            Navigator.of(context)
                .popAndPushNamed(ActiveFirstSeenScreen.routeName);
          },
        ),
        drawer: const MyDrawer(),
        bottomNavigationBar: BottomSheet2(buttonList: [
          BottomNavyBarItem(
            onPressed: () async {
              bool checkTurnOnNetwork =
                  await checkTurnOnNetWork.turnOnWifiAndMobile();
              if (checkTurnOnNetwork) {
                if (!mounted) return;
                showCircularProgressIndicator(context: context);
                DateTime now = await timeNTP.get();
                Permit permit = Permit(
                  Plate: _vrnController.text,
                  ContraventionReasonCode: "36",
                  EventDateTime: now,
                  FirstObservedDateTime: now,
                  ZoneId: locationProvider.zone!.Id as int,
                );
                try {
                  await weakNetworkContraventionController
                      .checkHasPermit(permit)
                      .then((value) async {
                    Navigator.of(context).pop();
                    if (value?.hasPermit == true) {
                      if (!isCheckedPermit) {
                        showDialogPermitExists(value);
                      } else {
                        await addFirstSeenModeComplete();
                      }
                      setState(() {
                        isCheckedPermit = true;
                      });
                    } else {
                      await addFirstSeenModeComplete();
                    }
                  });
                } on DioError catch (error) {
                  if (!mounted) return;
                  if (error.type == DioErrorType.other ||
                      error.type == DioErrorType.connectTimeout) {
                    Navigator.of(context).pop();
                    await addFirstSeenModeComplete();
                    return;
                  }
                  sendMessageInternalServer(error);
                }
              } else {
                await addFirstSeenModeComplete();
              }
            },
            icon: SvgPicture.asset(
              'assets/svg/IconComplete2.svg',
            ),
            label: 'Complete',
          ),
          BottomNavyBarItem(
            onPressed: () async {
              bool checkTurnOnNetwork =
                  await checkTurnOnNetWork.turnOnWifiAndMobile();
              if (checkTurnOnNetwork) {
                if (!mounted) return;
                showCircularProgressIndicator(context: context);
                DateTime now = await timeNTP.get();
                Permit permit = Permit(
                    Plate: _vrnController.text,
                    ContraventionReasonCode: "36",
                    EventDateTime: now,
                    FirstObservedDateTime: now,
                    ZoneId: locationProvider.zone!.Id as int);
                try {
                  await weakNetworkContraventionController
                      .checkHasPermit(permit)
                      .then((value) async {
                    Navigator.of(context).pop();
                    if (value?.hasPermit == true) {
                      if (!isCheckedPermit) {
                        showDialogPermitExists(value);
                      } else {
                        await addFirstSeenModeCompleteAndAdd();
                      }
                      setState(() {
                        isCheckedPermit = true;
                      });
                    } else {
                      await addFirstSeenModeCompleteAndAdd();
                    }
                  });
                } on DioError catch (error) {
                  if (!mounted) return;
                  if (error.type == DioErrorType.other ||
                      error.type == DioErrorType.connectTimeout) {
                    Navigator.of(context).pop();
                    await addFirstSeenModeCompleteAndAdd();
                    return;
                  }
                  sendMessageInternalServer(error);
                }
              } else {
                await addFirstSeenModeCompleteAndAdd();
              }
            },
            icon: SvgPicture.asset(
              'assets/svg/IconSave2.svg',
              width: 20,
              height: 20,
              color: Colors.white,
            ),
            label: 'Complete & add',
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
                                flex: 7,
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
                                      } else if (value.length > 10) {
                                        return 'You can only enter up to 10 characters';
                                      }
                                      return null;
                                    }
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      validateMode =
                                          AutovalidateMode.onUserInteraction;
                                      isCheckedPermit = false;
                                    });
                                  },
                                  autovalidateMode: validateMode,
                                ),
                              ),
                              Flexible(
                                flex: 4,
                                child: ElevatedButton.icon(
                                  icon: SvgPicture.asset(
                                    'assets/svg/IconComplete.svg',
                                    color: Colors.white,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: checkVrnIsValid()
                                      ? () async {
                                          bool checkTurnOnNetwork =
                                              await checkTurnOnNetWork
                                                  .turnOnWifiAndMobile();
                                          if (checkTurnOnNetwork) {
                                            if (!mounted) return;
                                            showCircularProgressIndicator(
                                                context: context);
                                            DateTime now = await timeNTP.get();
                                            Permit permit = Permit(
                                                Plate: _vrnController.text,
                                                ContraventionReasonCode: "36",
                                                EventDateTime: now,
                                                FirstObservedDateTime: now,
                                                ZoneId: locationProvider
                                                    .zone!.Id as int);
                                            try {
                                              await weakNetworkContraventionController
                                                  .checkHasPermit(permit)
                                                  .then((value) async {
                                                Navigator.of(context).pop();
                                                if (value?.hasPermit == true) {
                                                  showDialogPermitExists(value);
                                                } else {
                                                  showErrorMessage(
                                                      'There is no permit for this VRN');
                                                }
                                              });
                                            } on DioError catch (error) {
                                              if (!mounted) return;
                                              if (error.type ==
                                                      DioErrorType.other ||
                                                  error.type ==
                                                      DioErrorType
                                                          .connectTimeout) {
                                                Navigator.of(context).pop();
                                                showErrorMessage(
                                                    'Check permit failed because poor connection');
                                              }
                                              sendMessageInternalServer(error);
                                            }
                                          } else {
                                            if (!mounted) return;
                                            showErrorMessage(
                                                'Unable to check permit due to lack of internet');
                                          }
                                        }
                                      : null,
                                  label: const Text(
                                    "Check permit",
                                  ),
                                ),
                              ),
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
                                    titleCamera: "Take evidence photo",
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

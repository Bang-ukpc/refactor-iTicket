import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/button_scan.dart';
import 'package:iWarden/common/drop_down_button.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/contraventions.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/demo-ocr/anyline_service.dart';
import 'package:iWarden/screens/demo-ocr/result.dart';
import 'package:iWarden/screens/demo-ocr/scan_modes.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_info.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/screens/parking-charges/print_pcn.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

List<SelectModel> typeOfPCN = [
  SelectModel(label: 'Virtual ticket (Highly recommended)', value: 0),
  SelectModel(label: 'Physical PCN', value: 1),
];

class IssuePCNFirstSeenScreen extends StatefulWidget {
  static const routeName = '/issue-pcn';

  const IssuePCNFirstSeenScreen({Key? key}) : super(key: key);

  @override
  State<IssuePCNFirstSeenScreen> createState() =>
      _IssuePCNFirstSeenScreenState();
}

class _IssuePCNFirstSeenScreenState extends State<IssuePCNFirstSeenScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnylineService _anylineService;
  final TextEditingController _vrnController = TextEditingController();
  final TextEditingController _vehicleMakeController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _contraventionReasonController =
      TextEditingController();
  final TextEditingController _typeOfPcnController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  int selectedButton = 0;
  List<File> arrayImage = [];
  List<EvidencePhoto> evidencePhotoList = [];
  final _debouncer = Debouncer(milliseconds: 500);

  void getContraventionReasonListFrProvider(
      Contraventions contraventionProvider) async {
    await contraventionProvider.getContraventionReasonList().then((value) {
      setState(() {
        contraventionReasonList = value;
      });
    });
  }

  void onSearchVehicleInfoByPlate(String plate) async {
    await contraventionController
        .getVehicleDetailByPlate(plate: plate)
        .then((value) {
      setState(() {
        _vehicleMakeController.text = value?.make ?? '';
        _vehicleColorController.text = value?.colour ?? '';
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _anylineService = AnylineServiceImpl();
    _typeOfPcnController.text = '0';
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final contraventionProvider =
          Provider.of<Contraventions>(context, listen: false);
      getContraventionReasonListFrProvider(contraventionProvider);
      final args = ModalRoute.of(context)!.settings.arguments as dynamic;
      _vrnController.text = args != null ? args.Plate : '';
      if (args != null) {
        onSearchVehicleInfoByPlate(args.Plate);
      }
    });
  }

  Future<void> scan(ScanMode mode) async {
    try {
      Result? result = await _anylineService.scan(mode);
      if (result != null) {
        String resultText = result.jsonMap!.values
            .take(2)
            .toString()
            .split(',')[1]
            .replaceAll(' ', '');
        setState(() {
          _vrnController.text = resultText.substring(0, resultText.length - 1);
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
    _vehicleMakeController.dispose();
    _vehicleColorController.dispose();
    _typeOfPcnController.dispose();
    _commentController.dispose();
    _contraventionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<Locations>(context);
    final wardersProvider = Provider.of<WardensInfo>(context);
    final args = ModalRoute.of(context)!.settings.arguments as dynamic;

    ContraventionCreateWardenCommand physicalPCN =
        ContraventionCreateWardenCommand(
      ExternalReference: locationProvider.zone!.ExternalReference,
      ContraventionReference: '',
      Plate: _vrnController.text,
      VehicleMake: _vehicleMakeController.text,
      VehicleColour: _vehicleColorController.text,
      ContraventionReasonCode: _contraventionReasonController.text,
      EventDateTime: DateTime.now(),
      FirstObservedDateTime: args != null ? args.Created : DateTime.now(),
      WardenId: wardersProvider.wardens?.Id ?? 0,
      Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      WardenComments: _commentController.text,
      BadgeNumber: 'test',
      LocationAccuracy: 0, // missing
    );

    ContraventionCreateWardenCommand virtualTicket =
        ContraventionCreateWardenCommand(
      ExternalReference: locationProvider.zone!.ExternalReference,
      ContraventionReference: '',
      Plate: _vrnController.text,
      VehicleMake: _vehicleMakeController.text,
      VehicleColour: _vehicleColorController.text,
      ContraventionReasonCode: _contraventionReasonController.text,
      EventDateTime: DateTime.now(),
      FirstObservedDateTime: args != null ? args.Created : DateTime.now(),
      WardenId: wardersProvider.wardens?.Id ?? 0,
      Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      WardenComments: _commentController.text,
      BadgeNumber: 'test',
      LocationAccuracy: 0, // missing
    );

    void showLoading() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Future<void> createPhysicalPCN() async {
      final isValid = _formKey.currentState!.validate();
      Contravention? contravention;
      bool check = false;

      if (arrayImage.isEmpty) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'Please take at least 1 picture',
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        return;
      }
      if (!isValid) {
        return;
      } else {
        showLoading();
      }
      try {
        await contraventionController.createPCN(physicalPCN).then((value) {
          contravention = value;
        });
        if (arrayImage.isNotEmpty && contravention != null) {
          for (int i = 0; i < arrayImage.length; i++) {
            await contraventionController.uploadContraventionImage(
              ContraventionCreatePhoto(
                contraventionReference: contravention?.reference ?? '',
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                file: arrayImage[i],
              ),
            );
            if (i == arrayImage.length - 1) {
              check = true;
            }
          }
        }
        if (contravention != null && check == true) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
          // ignore: use_build_context_synchronously
          Navigator.of(context)
              .pushNamed(PrintPCN.routeName, arguments: contravention);
        }
      } on DioError catch (error) {
        if (error.response!.statusCode == 400) {
          Navigator.of(context).pop();
          CherryToast.error(
            toastDuration: const Duration(seconds: 2),
            displayCloseButton: true,
            title: Text(
              error.response!.data['message'].toString().length > 30
                  ? 'Something went wrong'
                  : error.response!.data['message'],
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        } else {
          Navigator.of(context).pop();
          CherryToast.error(
            displayCloseButton: false,
            title: Text(
              error.response!.data['message'].toString().length > 30
                  ? 'Something went wrong'
                  : error.response!.data['message'],
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
      }

      _formKey.currentState!.save();
    }

    Future<void> createVirtualTicket() async {
      final isValid = _formKey.currentState!.validate();
      Contravention? contravention;
      bool check = false;

      if (arrayImage.isEmpty) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'Please take at least 1 picture',
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        return;
      }
      if (!isValid) {
        return;
      } else {
        showLoading();
      }
      try {
        await contraventionController.createPCN(virtualTicket).then((value) {
          contravention = value;
        });
        if (arrayImage.isNotEmpty && contravention != null) {
          for (int i = 0; i < arrayImage.length; i++) {
            await contraventionController.uploadContraventionImage(
              ContraventionCreatePhoto(
                contraventionReference: contravention?.reference ?? '',
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                file: arrayImage[i],
              ),
            );
            if (i == arrayImage.length - 1) {
              check = true;
            }
          }
        }
        if (contravention != null && check == true) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamed(
            ParkingChargeInfo.routeName,
            arguments: contravention,
          );
        }
      } on DioError catch (error) {
        if (error.response!.statusCode == 400) {
          Navigator.of(context).pop();
          CherryToast.error(
            toastDuration: const Duration(seconds: 2),
            displayCloseButton: true,
            title: Text(
              error.response!.data['message'].toString().length > 30
                  ? 'Something went wrong'
                  : error.response!.data['message'],
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        } else {
          Navigator.of(context).pop();
          CherryToast.error(
            displayCloseButton: false,
            title: Text(
              error.response!.data['message'].toString().length > 30
                  ? 'Something went wrong'
                  : error.response!.data['message'],
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
      }

      _formKey.currentState!.save();
    }

    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            buttonCancel: false,
            title: const Text(
              "Suggestion for you",
              style: TextStyle(color: ColorTheme.success),
            ),
            subTitle: const Text(
              "Virtual ticketing is enabled for this site, we would encourage you to use virtual ticketing.",
              textAlign: TextAlign.center,
              style: CustomTextStyle.body2,
            ),
            func: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                    ),
                    child: const Text("Switch to virtual ticketing"),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      createVirtualTicket();
                    },
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        ColorTheme.grey300,
                      ),
                      elevation: MaterialStateProperty.all(0),
                      foregroundColor: MaterialStateProperty.all(
                        ColorTheme.textPrimary,
                      ),
                    ),
                    child: const Text("Proceed with physical ticketing"),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      createPhysicalPCN();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          appBar: MyAppBar(
            title: "Issue PCN",
            automaticallyImplyLeading: true,
            onRedirect: () {
              Navigator.of(context)
                  .popAndPushNamed(ParkingChargeList.routeName);
            },
          ),
          drawer: const MyDrawer(),
          bottomSheet: BottomSheet2(
            buttonList: [
              if (_typeOfPcnController.text == '0')
                BottomNavyBarItem(
                  onPressed: () {
                    createVirtualTicket();
                  },
                  icon: SvgPicture.asset('assets/svg/IconComplete2.svg'),
                  label: const Text(
                    'Complete',
                    style: CustomTextStyle.h6,
                  ),
                ),
              if (_typeOfPcnController.text == '1')
                BottomNavyBarItem(
                  onPressed: () {
                    final isValid = _formKey.currentState!.validate();
                    if (arrayImage.isEmpty) {
                      CherryToast.error(
                        displayCloseButton: false,
                        title: Text(
                          'Please take at least 1 picture',
                          style: CustomTextStyle.h5
                              .copyWith(color: ColorTheme.danger),
                        ),
                        toastPosition: Position.bottom,
                        borderRadius: 5,
                      ).show(context);
                      return;
                    }
                    if (!isValid) {
                      return;
                    } else {
                      showMyDialog();
                    }
                  },
                  icon: SvgPicture.asset('assets/svg/IconComplete2.svg'),
                  label: const Text(
                    'Save & print PCN',
                    style: CustomTextStyle.h6,
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.only(
                  bottom: ConstSpacing.bottom + 20, top: 20),
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
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
                                  style: CustomTextStyle.h5,
                                  decoration: const InputDecoration(
                                    label: LabelRequire(labelText: "VRN"),
                                    hintText: "Enter VRN",
                                  ),
                                  validator: ((value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter VRN';
                                    }
                                    return null;
                                  }),
                                  onSaved: (value) {
                                    _vrnController.text = value as String;
                                  },
                                  onChanged: (value) {
                                    _debouncer.run(() {
                                      onSearchVehicleInfoByPlate(value);
                                    });
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
                            height: 20,
                          ),
                          TextFormField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[^\s]+\b\s?'),
                              ),
                            ],
                            style: CustomTextStyle.h5,
                            controller: _vehicleMakeController,
                            decoration: const InputDecoration(
                              label: LabelRequire(labelText: "Vehicle make"),
                              hintText: "Enter vehicle make",
                            ),
                            validator: ((value) {
                              if (value!.isEmpty) {
                                return 'Please enter vehicle make';
                              }
                              return null;
                            }),
                            onSaved: (value) {
                              _vehicleMakeController.text = value as String;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[^\s]+\b\s?'),
                              ),
                            ],
                            style: CustomTextStyle.h5,
                            controller: _vehicleColorController,
                            decoration: const InputDecoration(
                              label: LabelRequire(labelText: "Vehicle color"),
                              hintText: "Enter vehicle color",
                            ),
                            validator: ((value) {
                              if (value!.isEmpty) {
                                return 'Please enter vehicle color';
                              }
                              return null;
                            }),
                            onSaved: (value) {
                              _vehicleColorController.text = value as String;
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            child: DropDownButtonWidget(
                              labelText: const LabelRequire(
                                labelText: 'Contravention',
                              ),
                              hintText: 'Select contravention',
                              item: contraventionReasonList
                                  .map(
                                    (itemValue) => DropdownMenuItem(
                                      value:
                                          itemValue.contraventionReason!.code,
                                      child: Text(
                                        itemValue.summary as String,
                                        style: CustomTextStyle.h5,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onchanged: (value) {
                                setState(() {
                                  _contraventionReasonController.text =
                                      value as String;
                                });
                              },
                              value:
                                  _contraventionReasonController.text.isNotEmpty
                                      ? _contraventionReasonController.text
                                      : null,
                              validator: ((value) {
                                if (value == null) {
                                  return 'Please select contravention';
                                }
                                return null;
                              }),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            child: DropDownButtonWidget(
                              labelText: const LabelRequire(
                                labelText: 'Type of PCN',
                              ),
                              hintText: 'Select type of PCN',
                              item: typeOfPCN
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item.value.toString(),
                                      child: Text(
                                        item.label,
                                        style: CustomTextStyle.h5,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onchanged: (value) {
                                setState(() {
                                  _typeOfPcnController.text = value.toString();
                                });
                              },
                              value: _typeOfPcnController.text.isNotEmpty
                                  ? _typeOfPcnController.text
                                  : null,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[^\s]+\b\s?'),
                              ),
                            ],
                            controller: _commentController,
                            style: CustomTextStyle.h5,
                            keyboardType: TextInputType.multiline,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: "Comment",
                              hintText: "Enter comment",
                            ),
                            onSaved: (value) {
                              _commentController.text = value as String;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  AddImage(
                    onAddImage: () async {
                      final results =
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CameraPicker(
                                    titleCamera: "Issue parking charge",
                                    onDelete: (file) {
                                      return true;
                                    },
                                  )));
                      if (results != null) {
                        setState(() {
                          arrayImage = List.from(results);
                        });
                      }
                    },
                    listImage: arrayImage,
                    isCamera: true,
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

class SelectModel {
  final String label;
  final int value;

  SelectModel({required this.label, required this.value});
}

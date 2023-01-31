import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/button_scan.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/configs/scan-plate/anyline_service.dart';
import 'package:iWarden/configs/scan-plate/result.dart';
import 'package:iWarden/configs/scan-plate/scan_modes.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/print_issue.dart';
import 'package:iWarden/screens/parking-charges/print_pcn.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/print_issue_providers.dart' as prefix;
import '../../widgets/parking-charge/step_issue_pcn.dart';

List<SelectModel> typeOfPCN = [
  SelectModel(label: 'Virtual ticket (Highly recommended)', value: 1),
  SelectModel(label: 'Physical PCN', value: 0),
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
  final _vrnController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _contraventionReasonController = TextEditingController();
  final _commentController = TextEditingController();
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  List<EvidencePhoto> evidencePhotoList = [];
  final _debouncer = Debouncer(milliseconds: 300);
  SelectModel? _selectedItemTypePCN;

  void getContraventionReasonList() async {
    final Pagination list =
        await contraventionController.getContraventionReasonServiceList();
    setState(() {
      contraventionReasonList = list.rows
          .map((item) => ContraventionReasonTranslations.fromJson(item))
          .toList();
    });
  }

  void onSearchVehicleInfoByPlate(String plate) async {
    await contraventionController
        .getVehicleDetailByPlate(plate: plate)
        .then((value) {
      setState(() {
        _vehicleMakeController.text = value?.Make ?? '';
        _vehicleModelController.text = value?.Model ?? '';
        _vehicleColorController.text = value?.Colour ?? '';
      });
    });
  }

  void getSelectedTypeOfPCN(
      Locations locationProvider, Contravention? contraventionValue) {
    var typeOfPCNFilter = typeOfPCN.where((e) {
      if (locationProvider
                  .zone!.Services![0].ServiceConfig.IssuePCNType.Physical ==
              true &&
          locationProvider
                  .zone!.Services![0].ServiceConfig.IssuePCNType.Virtual ==
              true) {
        return true;
      } else if (locationProvider
              .zone!.Services![0].ServiceConfig.IssuePCNType.Physical ==
          true) {
        return e.value == 0;
      } else {
        return e.value == 1;
      }
    }).toList();
    if (contraventionValue != null) {
      setState(() {
        _selectedItemTypePCN = typeOfPCNFilter
            .firstWhere((e) => e.value == contraventionValue.type);
      });
    } else {
      setState(() {
        _selectedItemTypePCN = typeOfPCNFilter[0];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _anylineService = AnylineServiceImpl();
    getContraventionReasonList();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final args = ModalRoute.of(context)!.settings.arguments as dynamic;
      final locationProvider = Provider.of<Locations>(context, listen: false);
      final contraventionProvider =
          Provider.of<ContraventionProvider>(context, listen: false);
      _vrnController.text = args != null ? args.Plate : '';
      var contraventionData = contraventionProvider.contravention;
      if (contraventionData != null) {
        _vrnController.text = contraventionData.plate ?? '';
        _vehicleMakeController.text = contraventionData.make ?? '';
        _vehicleModelController.text = contraventionData.model ?? '';
        _vehicleColorController.text = contraventionData.colour ?? '';
        _contraventionReasonController.text =
            contraventionData.reason?.code ?? '';
        _commentController.text = contraventionData.contraventionEvents!
            .map((item) => item.detail)
            .toString()
            .replaceAll('(', '')
            .replaceAll(')', '');
      }
      if (args != null) {
        onSearchVehicleInfoByPlate(args.Plate);
      }
      getSelectedTypeOfPCN(locationProvider, contraventionData);
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
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _commentController.dispose();
    _contraventionReasonController.dispose();
    if (_debouncer.timer != null) {
      _debouncer.timer!.cancel();
    }
    contraventionReasonList.clear();
    evidencePhotoList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    final contraventionProvider = Provider.of<ContraventionProvider>(context);
    final args = ModalRoute.of(context)!.settings.arguments as dynamic;
    final printIssue = Provider.of<prefix.PrintIssueProviders>(context);

    log('Issue PCN screen');

    Future<void> createPhysicalPCN({bool? step2, bool? step3}) async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomNumber = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
      final physicalPCN = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference: '$randomReference',
        Plate: _vrnController.text,
        VehicleMake: _vehicleMakeController.text,
        VehicleColour: _vehicleColorController.text,
        ContraventionReasonCode: _contraventionReasonController.text,
        EventDateTime: DateTime.now(),
        FirstObservedDateTime: args != null ? args.Created : DateTime.now(),
        WardenId: wardensProvider.wardens?.Id ?? 0,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        WardenComments: _commentController.text,
        BadgeNumber: 'test',
        LocationAccuracy: 0, // missing
        TypePCN: TypePCN.Physical.index,
        Id: randomNumber,
      );

      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      } else {
        if (!mounted) return;
        showCircularProgressIndicator(context: context);
      }
      List<ContraventionPhotos> contraventionImageList = [];
      if (printIssue.data.isNotEmpty) {
        for (int i = 0; i < printIssue.data.length; i++) {
          if (printIssue.data[i].image != null) {
            contraventionImageList.add(ContraventionPhotos(
              blobName: printIssue.data[i].image!.path,
              contraventionId: contraventionProvider.contravention?.id ?? 0,
            ));
          }
        }
      }
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        Contravention contravention = Contravention(
          reference: physicalPCN.ContraventionReference,
          created: DateTime.now(),
          id: physicalPCN.Id,
          plate: physicalPCN.Plate,
          colour: physicalPCN.VehicleColour,
          make: physicalPCN.VehicleMake,
          model: _vehicleModelController.text,
          eventDateTime: physicalPCN.EventDateTime,
          zoneId: locationProvider.zone?.Id ?? 0,
          reason: Reason(
            code: physicalPCN.ContraventionReasonCode,
            contraventionReasonTranslations: contraventionReasonList
                .where((e) =>
                    e.contraventionReason!.code ==
                    physicalPCN.ContraventionReasonCode)
                .toList(),
          ),
          contraventionEvents: [
            ContraventionEvents(
              contraventionId: physicalPCN.Id,
              detail: physicalPCN.WardenComments,
            )
          ],
          contraventionDetailsWarden: ContraventionDetailsWarden(
            FirstObserved: physicalPCN.FirstObservedDateTime,
            ContraventionId: physicalPCN.Id,
            WardenId: physicalPCN.WardenId,
            IssuedAt: physicalPCN.EventDateTime,
          ),
          status: ContraventionStatus.Open.index,
          type: physicalPCN.TypePCN,
          contraventionPhotos: contraventionImageList,
        );

        if (!mounted) return;
        contraventionProvider.upDateContravention(contravention);
        Navigator.of(context).pop();
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName)
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context)
                    .pushReplacementNamed(PrintIssue.routeName);
      } else {
        final String? reasonDataLocal =
            await SharedPreferencesHelper.getStringValue(
                'contraventionReasonDataLocal');
        final contraventionReason =
            json.decode(reasonDataLocal as String) as Map<String, dynamic>;
        Pagination fromJsonContraventionReason =
            Pagination.fromJson(contraventionReason);
        List<ContraventionReasonTranslations> fromJsonContraventionList =
            fromJsonContraventionReason.rows
                .map((item) => ContraventionReasonTranslations.fromJson(item))
                .toList();

        Contravention contraventionDataFake = Contravention(
          reference: physicalPCN.ContraventionReference,
          created: DateTime.now(),
          id: physicalPCN.Id,
          plate: physicalPCN.Plate,
          colour: physicalPCN.VehicleColour,
          make: physicalPCN.VehicleMake,
          model: _vehicleModelController.text,
          eventDateTime: physicalPCN.EventDateTime,
          zoneId: locationProvider.zone?.Id ?? 0,
          reason: Reason(
            code: physicalPCN.ContraventionReasonCode,
            contraventionReasonTranslations: fromJsonContraventionList
                .where((e) =>
                    e.contraventionReason!.code ==
                    physicalPCN.ContraventionReasonCode)
                .toList(),
          ),
          contraventionEvents: [
            ContraventionEvents(
              contraventionId: physicalPCN.Id,
              detail: physicalPCN.WardenComments,
            )
          ],
          contraventionDetailsWarden: ContraventionDetailsWarden(
            FirstObserved: physicalPCN.FirstObservedDateTime,
            ContraventionId: physicalPCN.Id,
            WardenId: physicalPCN.WardenId,
            IssuedAt: physicalPCN.EventDateTime,
          ),
          status: ContraventionStatus.Open.index,
          type: physicalPCN.TypePCN,
          contraventionPhotos: contraventionImageList,
        );

        if (!mounted) return;
        contraventionProvider.upDateContravention(contraventionDataFake);
        Navigator.of(context).pop();
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName)
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context)
                    .pushReplacementNamed(PrintIssue.routeName);
      }

      _formKey.currentState!.save();
    }

    Future<void> createVirtualTicket({bool? step2, bool? step3}) async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomNumber = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
      final virtualTicket = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference: '$randomReference',
        Plate: _vrnController.text,
        VehicleMake: _vehicleMakeController.text,
        VehicleColour: _vehicleColorController.text,
        ContraventionReasonCode: _contraventionReasonController.text,
        EventDateTime: DateTime.now(),
        FirstObservedDateTime: args != null ? args.Created : DateTime.now(),
        WardenId: wardensProvider.wardens?.Id ?? 0,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        WardenComments: _commentController.text,
        BadgeNumber: 'test',
        LocationAccuracy: 0, // missing
        TypePCN: TypePCN.Virtual.index,
        Id: randomNumber,
      );

      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      } else {
        if (!mounted) return;
        showCircularProgressIndicator(context: context);
      }
      List<ContraventionPhotos> contraventionImageList = [];
      if (printIssue.data.isNotEmpty) {
        for (int i = 0; i < printIssue.data.length; i++) {
          if (printIssue.data[i].image != null && printIssue.data[i].id != 2) {
            contraventionImageList.add(ContraventionPhotos(
              blobName: printIssue.data[i].image!.path,
              contraventionId: contraventionProvider.contravention?.id ?? 0,
            ));
          }
        }
      }
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        Contravention contravention = Contravention(
          reference: virtualTicket.ContraventionReference,
          created: DateTime.now(),
          id: virtualTicket.Id,
          plate: virtualTicket.Plate,
          colour: virtualTicket.VehicleColour,
          make: virtualTicket.VehicleMake,
          model: _vehicleModelController.text,
          eventDateTime: virtualTicket.EventDateTime,
          zoneId: locationProvider.zone?.Id ?? 0,
          reason: Reason(
            code: virtualTicket.ContraventionReasonCode,
            contraventionReasonTranslations: contraventionReasonList
                .where((e) =>
                    e.contraventionReason!.code ==
                    virtualTicket.ContraventionReasonCode)
                .toList(),
          ),
          contraventionEvents: [
            ContraventionEvents(
              contraventionId: virtualTicket.Id,
              detail: virtualTicket.WardenComments,
            )
          ],
          contraventionDetailsWarden: ContraventionDetailsWarden(
            FirstObserved: virtualTicket.FirstObservedDateTime,
            ContraventionId: virtualTicket.Id,
            WardenId: virtualTicket.WardenId,
            IssuedAt: virtualTicket.EventDateTime,
          ),
          status: ContraventionStatus.Open.index,
          type: virtualTicket.TypePCN,
          contraventionPhotos: contraventionImageList,
        );
        if (!mounted) return;
        contraventionProvider.upDateContravention(contravention);
        Navigator.of(context).pop();
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName)
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context)
                    .pushReplacementNamed(PrintIssue.routeName);
      } else {
        final String? reasonDataLocal =
            await SharedPreferencesHelper.getStringValue(
                'contraventionReasonDataLocal');
        final contraventionReason =
            json.decode(reasonDataLocal as String) as Map<String, dynamic>;
        Pagination fromJsonContraventionReason =
            Pagination.fromJson(contraventionReason);
        List<ContraventionReasonTranslations> fromJsonContraventionList =
            fromJsonContraventionReason.rows
                .map((item) => ContraventionReasonTranslations.fromJson(item))
                .toList();

        Contravention contraventionDataFake = Contravention(
          reference: virtualTicket.ContraventionReference,
          created: DateTime.now(),
          id: virtualTicket.Id,
          plate: virtualTicket.Plate,
          colour: virtualTicket.VehicleColour,
          make: virtualTicket.VehicleMake,
          model: _vehicleModelController.text,
          eventDateTime: virtualTicket.EventDateTime,
          zoneId: locationProvider.zone?.Id ?? 0,
          reason: Reason(
            code: virtualTicket.ContraventionReasonCode,
            contraventionReasonTranslations: fromJsonContraventionList
                .where((e) =>
                    e.contraventionReason!.code ==
                    virtualTicket.ContraventionReasonCode)
                .toList(),
          ),
          contraventionEvents: [
            ContraventionEvents(
              contraventionId: virtualTicket.Id,
              detail: virtualTicket.WardenComments,
            )
          ],
          contraventionDetailsWarden: ContraventionDetailsWarden(
            FirstObserved: virtualTicket.FirstObservedDateTime,
            ContraventionId: virtualTicket.Id,
            WardenId: virtualTicket.WardenId,
            IssuedAt: virtualTicket.EventDateTime,
          ),
          status: ContraventionStatus.Open.index,
          type: virtualTicket.TypePCN,
          contraventionPhotos: contraventionImageList,
        );

        if (!mounted) return;
        contraventionProvider.upDateContravention(contraventionDataFake);
        Navigator.of(context).pop();
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName)
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context)
                    .pushReplacementNamed(PrintIssue.routeName);
      }

      _formKey.currentState!.save();
    }

    List<SelectModel> getSelectedTypeOfPCN() {
      return typeOfPCN.where((e) {
        if (locationProvider
                    .zone!.Services![0].ServiceConfig.IssuePCNType.Physical ==
                true &&
            locationProvider
                    .zone!.Services![0].ServiceConfig.IssuePCNType.Virtual ==
                true) {
          return true;
        } else if (locationProvider
                .zone!.Services![0].ServiceConfig.IssuePCNType.Physical ==
            true) {
          return e.value == 0;
        } else {
          return e.value == 1;
        }
      }).toList();
    }

    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierColor: ColorTheme.backdrop,
        barrierDismissible: false,
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
                      setState(() {
                        _selectedItemTypePCN = getSelectedTypeOfPCN()
                            .firstWhere((e) => e.value == 1);
                      });
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
                      setState(() {
                        _selectedItemTypePCN = getSelectedTypeOfPCN()
                            .firstWhere((e) => e.value == 0);
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void suggestion(SelectModel? value) {
      if (getSelectedTypeOfPCN().length > 1) {
        if (value?.value == 0) {
          showMyDialog();
        } else {
          setState(() {
            _selectedItemTypePCN = value;
          });
        }
      } else {
        setState(() {
          _selectedItemTypePCN = value;
        });
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          bottomNavigationBar: BottomSheet2(
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
                label: "Abort",
              ),
              if (_selectedItemTypePCN?.value == 1)
                BottomNavyBarItem(
                  onPressed: () {
                    createVirtualTicket();
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/IconNext.svg',
                    color: Colors.white,
                  ),
                  label: 'Next',
                ),
              if (_selectedItemTypePCN?.value == 0)
                BottomNavyBarItem(
                  onPressed: () {
                    createPhysicalPCN();
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/IconNext.svg',
                    color: Colors.white,
                  ),
                  label: 'Print & Next',
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(bottom: ConstSpacing.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                      padding: const EdgeInsets.fromLTRB(15, 16, 15, 30),
                      color: Colors.white,
                      child: Column(
                        children: [
                          StepIssuePCN(
                            isActiveStep1: true,
                            isActiveStep2: false,
                            onTap2: contraventionProvider.contravention != null
                                ? () {
                                    _selectedItemTypePCN!.value == 0
                                        ? createPhysicalPCN(step2: true)
                                        : createVirtualTicket(step2: true);
                                  }
                                : null,
                            isActiveStep3: false,
                            onTap3: contraventionProvider.contravention != null
                                ? contraventionProvider.contravention!
                                        .contraventionPhotos!.isNotEmpty
                                    ? () {
                                        _selectedItemTypePCN!.value == 0
                                            ? createPhysicalPCN(step3: true)
                                            : createVirtualTicket(step3: true);
                                      }
                                    : null
                                : null,
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    label:
                                        LabelRequire(labelText: "Vehicle make"),
                                    hintText: "Enter vehicle make",
                                  ),
                                  validator: ((value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter vehicle make';
                                    }
                                    return null;
                                  }),
                                  onSaved: (value) {
                                    _vehicleMakeController.text =
                                        value as String;
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
                                  controller: _vehicleModelController,
                                  decoration: const InputDecoration(
                                    label: LabelRequire(
                                        labelText: "Vehicle model"),
                                    hintText: "Enter vehicle model",
                                  ),
                                  validator: ((value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter vehicle model';
                                    }
                                    return null;
                                  }),
                                  onSaved: (value) {
                                    _vehicleModelController.text =
                                        value as String;
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
                                    label: LabelRequire(
                                        labelText: "Vehicle color"),
                                    hintText: "Enter vehicle color",
                                  ),
                                  validator: ((value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter vehicle color';
                                    }
                                    return null;
                                  }),
                                  onSaved: (value) {
                                    _vehicleColorController.text =
                                        value as String;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  child: DropdownSearch<
                                      ContraventionReasonTranslations>(
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      dropdownSearchDecoration:
                                          dropDownButtonStyle
                                              .getInputDecorationCustom(
                                        labelText: const LabelRequire(
                                          labelText: 'Contravention',
                                        ),
                                        hintText: 'Select contravention',
                                      ),
                                    ),
                                    items: contraventionReasonList,
                                    selectedItem: contraventionReasonList
                                            .isNotEmpty
                                        ? contraventionProvider.contravention !=
                                                null
                                            ? contraventionReasonList
                                                .firstWhere((e) =>
                                                    e.contraventionReason
                                                        ?.code ==
                                                    _contraventionReasonController
                                                        .text)
                                            : null
                                        : null,
                                    itemAsString: (item) =>
                                        item.summary as String,
                                    popupProps: PopupProps.menu(
                                        showSearchBox: true,
                                        fit: FlexFit.loose,
                                        constraints: const BoxConstraints(
                                          maxHeight: 325,
                                        ),
                                        itemBuilder:
                                            (context, item, isSelected) {
                                          return DropDownItem(
                                            isSelected: item
                                                    .contraventionReason!
                                                    .code ==
                                                _contraventionReasonController
                                                    .text,
                                            title: item.summary as String,
                                          );
                                        }),
                                    onChanged: (value) {
                                      setState(() {
                                        _contraventionReasonController.text =
                                            value!.contraventionReason!.code
                                                .toString();
                                      });
                                    },
                                    validator: ((value) {
                                      if (value == null) {
                                        return 'Please select contravention';
                                      }
                                      return null;
                                    }),
                                    autoValidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  child: DropdownSearch<SelectModel>(
                                    key: Key(
                                        '${DateTime.now().microsecondsSinceEpoch / 1000}'),
                                    dropdownDecoratorProps:
                                        DropDownDecoratorProps(
                                      dropdownSearchDecoration:
                                          dropDownButtonStyle
                                              .getInputDecorationCustom(
                                        labelText: const LabelRequire(
                                          labelText: 'Type of PCN',
                                        ),
                                        hintText: 'Select type of PCN',
                                      ),
                                    ),
                                    items: getSelectedTypeOfPCN(),
                                    selectedItem: _selectedItemTypePCN,
                                    itemAsString: (item) => item.label,
                                    popupProps: PopupProps.menu(
                                      fit: FlexFit.loose,
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      itemBuilder:
                                          (context, item, isSelected) =>
                                              DropDownItem(
                                        isSelected:
                                            item == _selectedItemTypePCN,
                                        title: item.label,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      suggestion(value);
                                    },
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

class SelectModel {
  final String label;
  final int value;

  SelectModel({required this.label, required this.value});
}

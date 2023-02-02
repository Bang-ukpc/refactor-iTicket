import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/car_info_data.dart';
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

import '../../models/location.dart';
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
  final _vrnController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _contraventionReasonController = TextEditingController();
  final _commentController = TextEditingController();
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  List<ContraventionReasonTranslations> fromJsonContraventionList = [];
  List<EvidencePhoto> evidencePhotoList = [];
  final _debouncer = Debouncer(milliseconds: 300);
  SelectModel? _selectedItemTypePCN;
  List<RotaWithLocation> locationWithRotaList = [];

  void setSelectedTypeOfPCN(
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
      } else if (locationProvider
              .zone!.Services![0].ServiceConfig.IssuePCNType.Virtual ==
          true) {
        return e.value == 1;
      } else {
        return false;
      }
    }).toList();
    if (contraventionValue != null) {
      setState(() {
        _selectedItemTypePCN = typeOfPCNFilter
            .firstWhere((e) => e.value == contraventionValue.type);
      });
    } else {
      setState(() {
        _selectedItemTypePCN =
            typeOfPCNFilter.isNotEmpty ? typeOfPCNFilter[0] : null;
      });
    }
  }

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

  void getContraventionReasonList() async {
    final Pagination list =
        await contraventionController.getContraventionReasonServiceList();
    setState(() {
      contraventionReasonList = list.rows
          .map((item) => ContraventionReasonTranslations.fromJson(item))
          .toList();
    });
  }

  void getContraventionReasonListOffline() async {
    final String? reasonDataLocal =
        await SharedPreferencesHelper.getStringValue(
            'contraventionReasonDataLocal');
    final contraventionReason =
        json.decode(reasonDataLocal as String) as Map<String, dynamic>;
    Pagination fromJsonContraventionReason =
        Pagination.fromJson(contraventionReason);
    fromJsonContraventionList = fromJsonContraventionReason.rows
        .map((item) => ContraventionReasonTranslations.fromJson(item))
        .toList();
  }

  void onSearchVehicleInfoByPlate(String plate) async {
    await contraventionController
        .getVehicleDetailByPlate(plate: plate)
        .then((value) {
      setState(() {
        _vehicleMakeController.text = value?.Make ?? '';
        _vehicleColorController.text = value?.Colour ?? '';
      });
    }).catchError(((e) {
      setState(() {
        _vehicleMakeController.text = '';
        _vehicleColorController.text = '';
      });
    }));
  }

  @override
  void initState() {
    super.initState();
    getContraventionReasonList();
    getContraventionReasonListOffline();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final args = ModalRoute.of(context)!.settings.arguments as dynamic;
      final locationProvider = Provider.of<Locations>(context, listen: false);
      final contraventionProvider =
          Provider.of<ContraventionProvider>(context, listen: false);
      final wardersProvider = Provider.of<WardensInfo>(context, listen: false);
      var contraventionData = contraventionProvider.contravention;
      await getLocationList(locationProvider, wardersProvider.wardens?.Id ?? 0)
          .then((value) {
        setSelectedTypeOfPCN(locationProvider, contraventionData);
      });

      _vrnController.text = args != null ? args.Plate : '';
      if (contraventionData != null) {
        _vrnController.text = contraventionData.plate ?? '';
        _vehicleMakeController.text = contraventionData.make ?? '';
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
        if (args.Type == VehicleInformationType.FIRST_SEEN.index) {
          ContraventionReasonTranslations? argsOverstayingTime =
              fromJsonContraventionList.firstWhereOrNull((e) => e.summary!
                  .toUpperCase()
                  .contains('Overstaying'.toUpperCase()));
          _contraventionReasonController.text = argsOverstayingTime != null
              ? argsOverstayingTime.contraventionReason!.code.toString()
              : '';
        } else {
          _contraventionReasonController.text = '';
        }
      }
      setSelectedTypeOfPCN(locationProvider, contraventionData);
    });
  }

  @override
  void dispose() {
    _vrnController.dispose();
    _vehicleMakeController.dispose();
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
    final argsFromExpired =
        ModalRoute.of(context)!.settings.arguments as dynamic;
    int randomNumber = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();

    log('Issue PCN screen');

    int randomReference =
        (DateTime.now().microsecondsSinceEpoch / 10000).ceil();
    final physicalPCN = ContraventionCreateWardenCommand(
      ZoneId: locationProvider.zone?.Id ?? 0,
      ContraventionReference: '2$randomReference',
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

    Future<void> createPhysicalPCN(
        {bool? step2, bool? step3, required bool isPrinter}) async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());

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
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName,
                arguments: {'isPrinter': isPrinter})
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context).pushReplacementNamed(
                    PrintIssue.routeName,
                    arguments: {'isPrinter': isPrinter});
      } else {
        Contravention contraventionDataFake = Contravention(
          reference: physicalPCN.ContraventionReference,
          created: DateTime.now(),
          id: physicalPCN.Id,
          plate: physicalPCN.Plate,
          colour: physicalPCN.VehicleColour,
          make: physicalPCN.VehicleMake,
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
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName,
                arguments: {'isPrinter': isPrinter})
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context).pushReplacementNamed(
                    PrintIssue.routeName,
                    arguments: {'isPrinter': isPrinter});
      }

      _formKey.currentState!.save();
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
                      Row(
                        children: [
                          const Text(
                            'VRN: ',
                            style: CustomTextStyle.h5,
                          ),
                          Text(
                            value?.permitInfo?.VRN ?? 'No data',
                            style: CustomTextStyle.h5
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Text(
                            'Bay information: ',
                            style: CustomTextStyle.h5,
                          ),
                          Text(
                            value?.permitInfo?.bayNumber ?? 'No data',
                            style: CustomTextStyle.h5
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Text(
                            'Source: ',
                            style: CustomTextStyle.h5,
                          ),
                          Text(
                            value?.permitInfo?.source ?? 'No data',
                            style: CustomTextStyle.h5
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Text(
                            'Tenant: ',
                            style: CustomTextStyle.h5,
                          ),
                          Text(
                            value?.permitInfo?.tenant ?? 'No data',
                            style: CustomTextStyle.h5
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: ColorTheme.danger,
                              ),
                              child: Text(
                                "Abort",
                                style: CustomTextStyle.h4
                                    .copyWith(color: ColorTheme.white),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AbortScreen.routeName,
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: ColorTheme.primary,
                              ),
                              child: Text(
                                "Issue PCN",
                                style: CustomTextStyle.h4
                                    .copyWith(color: ColorTheme.white),
                              ),
                              onPressed: () {
                                createPhysicalPCN(isPrinter: true);
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

    Future<void> createVirtualTicket({bool? step2, bool? step3}) async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomNumber = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 10000).ceil();
      final virtualTicket = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference: '3$randomReference',
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
        Contravention contraventionDataFake = Contravention(
          reference: virtualTicket.ContraventionReference,
          created: DateTime.now(),
          id: virtualTicket.Id,
          plate: virtualTicket.Plate,
          colour: virtualTicket.VehicleColour,
          make: virtualTicket.VehicleMake,
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
        } else if (locationProvider
                .zone!.Services![0].ServiceConfig.IssuePCNType.Virtual ==
            true) {
          return e.value == 1;
        } else {
          return false;
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
              style: TextStyle(
                color: ColorTheme.success,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subTitle: const Text(
              "Virtual ticketing is enabled for this site, we would encourage you to use virtual ticketing.",
              textAlign: TextAlign.center,
              style: CustomTextStyle.h5,
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
                    child: const Text(
                      "Switch to virtual ticketing",
                      style: TextStyle(fontSize: 16),
                    ),
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
                    child: const Text(
                      "Proceed with physical ticketing",
                      style: TextStyle(fontSize: 16),
                    ),
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

    Future<void> refresh() async {
      await getLocationList(locationProvider, wardensProvider.wardens?.Id ?? 0)
          .then((value) {
        setSelectedTypeOfPCN(
            locationProvider, contraventionProvider.contravention);
      });
    }

    List<String> arrMake = DataInfoCar().make;
    List<String> arrColor = DataInfoCar().color;

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
                  onPressed: () async {
                    ConnectivityResult connectionStatus =
                        await (Connectivity().checkConnectivity());
                    if (connectionStatus == ConnectivityResult.wifi ||
                        connectionStatus == ConnectivityResult.mobile) {
                      try {
                        if (!mounted) return;
                        showCircularProgressIndicator(context: context);
                        await contraventionController
                            .checkHasPermit(physicalPCN)
                            .then((value) {
                          Navigator.of(context).pop();
                          if (value?.hasPermit == true) {
                            showDialogPermitExists(value);
                          } else {
                            createPhysicalPCN(isPrinter: true);
                          }
                        });
                      } on DioError catch (error) {
                        if (error.type == DioErrorType.other) {
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          CherryToast.error(
                            toastDuration: const Duration(seconds: 3),
                            title: Text(
                              error.message.length > Constant.errorTypeOther
                                  ? 'Something went wrong, please try again'
                                  : error.message,
                              style: CustomTextStyle.h4
                                  .copyWith(color: ColorTheme.danger),
                            ),
                            toastPosition: Position.bottom,
                            borderRadius: 5,
                          ).show(context);
                          return;
                        }
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        CherryToast.error(
                          displayCloseButton: false,
                          title: Text(
                            error.response!.data['message'].toString().length >
                                    Constant.errorMaxLength
                                ? 'Internal server error'
                                : error.response!.data['message'],
                            style: CustomTextStyle.h4
                                .copyWith(color: ColorTheme.danger),
                          ),
                          toastPosition: Position.bottom,
                          borderRadius: 5,
                        ).show(context);
                        return;
                      }
                    } else {
                      if (!mounted) return;
                      createPhysicalPCN(isPrinter: true);
                    }
                  },
                  icon: SvgPicture.asset(
                    'assets/svg/IconNext.svg',
                    color: Colors.white,
                  ),
                  label: 'Print & Next',
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                              onTap2: contraventionProvider.contravention !=
                                      null
                                  ? () {
                                      _selectedItemTypePCN!.value == 0
                                          ? createPhysicalPCN(
                                              step2: true, isPrinter: false)
                                          : createVirtualTicket(step2: true);
                                    }
                                  : null,
                              isActiveStep3: false,
                              isEnableStep3: _selectedItemTypePCN != null
                                  ? _selectedItemTypePCN!.value ==
                                          TypePCN.Physical.index
                                      ? printIssue.checkIssueHasPhotoRequirePhysical() ==
                                              true
                                          ? true
                                          : false
                                      : printIssue.checkIssueHasPhotoRequireVirtual() ==
                                              true
                                          ? true
                                          : false
                                  : false,
                              onTap3: _selectedItemTypePCN != null
                                  ? _selectedItemTypePCN!.value ==
                                          TypePCN.Physical.index
                                      ? printIssue.checkIssueHasPhotoRequirePhysical() ==
                                              true
                                          ? () {
                                              _selectedItemTypePCN!.value == 0
                                                  ? createPhysicalPCN(
                                                      step3: true,
                                                      isPrinter: false)
                                                  : createVirtualTicket(
                                                      step3: true);
                                            }
                                          : null
                                      : printIssue.checkIssueHasPhotoRequireVirtual() ==
                                              true
                                          ? () {
                                              _selectedItemTypePCN!.value == 0
                                                  ? createPhysicalPCN(
                                                      step3: true,
                                                      isPrinter: false)
                                                  : createVirtualTicket(
                                                      step3: true);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: CustomTextStyle.h5.copyWith(
                                            fontSize: 16,
                                          ),
                                          decoration: const InputDecoration(
                                              label: LabelRequire(
                                                  labelText: "VRN"),
                                              hintText: "Enter VRN",
                                              hintStyle: TextStyle(
                                                fontSize: 16,
                                                color: ColorTheme.grey400,
                                              )),
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
                                          onChanged: (value) {
                                            _debouncer.run(() {
                                              onSearchVehicleInfoByPlate(value);
                                            });
                                            _vrnController.text = value;
                                          },
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                    child: DropdownSearch<String>(
                                      dropdownBuilder: (context, selectedItem) {
                                        return Text(
                                            selectedItem ??
                                                "Select vehicle make",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: selectedItem == null
                                                  ? ColorTheme.grey400
                                                  : ColorTheme.textPrimary,
                                            ));
                                      },
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            dropDownButtonStyle
                                                .getInputDecorationCustom(
                                          labelText: const LabelRequire(
                                            labelText: "Vehicle make",
                                          ),
                                          hintText: "Select vehicle make",
                                        ),
                                      ),
                                      items: arrMake,
                                      selectedItem: contraventionProvider
                                                  .contravention !=
                                              null
                                          ? contraventionProvider
                                                      .contravention!.make !=
                                                  null
                                              ? arrMake.firstWhereOrNull((e) =>
                                                  e.toUpperCase() ==
                                                  contraventionProvider
                                                      .contravention!.make!
                                                      .toUpperCase())
                                              : null
                                          : _vehicleMakeController
                                                  .text.isNotEmpty
                                              ? arrMake.firstWhereOrNull((e) =>
                                                  e.toUpperCase() ==
                                                  _vehicleMakeController.text
                                                      .toUpperCase())
                                              : null,
                                      popupProps: PopupProps.menu(
                                          showSearchBox: true,
                                          fit: FlexFit.loose,
                                          constraints: const BoxConstraints(
                                            maxHeight: 325,
                                          ),
                                          itemBuilder:
                                              (context, item, isSelected) {
                                            return DropDownItem(
                                              isSelected: _vehicleMakeController
                                                      .text
                                                      .toUpperCase() ==
                                                  item.toUpperCase(),
                                              title: item,
                                            );
                                          }),
                                      onChanged: (value) {
                                        setState(() {
                                          _vehicleMakeController.text = value!;
                                        });
                                      },
                                      validator: ((value) {
                                        if (value == null) {
                                          return 'Please select make';
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
                                    child: DropdownSearch<String>(
                                      dropdownBuilder: (context, selectedItem) {
                                        return Text(
                                            selectedItem ??
                                                "Select vehicle color",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: selectedItem == null
                                                    ? ColorTheme.grey400
                                                    : ColorTheme.textPrimary));
                                      },
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            dropDownButtonStyle
                                                .getInputDecorationCustom(
                                          labelText: const LabelRequire(
                                            labelText: "Vehicle color",
                                          ),
                                          hintText: "Select vehicle color",
                                        ),
                                      ),
                                      items: arrColor,
                                      selectedItem: contraventionProvider
                                                  .contravention !=
                                              null
                                          ? contraventionProvider
                                                      .contravention!.colour !=
                                                  null
                                              ? arrColor.firstWhereOrNull((e) =>
                                                  e.toUpperCase() ==
                                                  contraventionProvider
                                                      .contravention!.colour!
                                                      .toUpperCase())
                                              : null
                                          : _vehicleColorController
                                                  .text.isNotEmpty
                                              ? arrColor.firstWhereOrNull((e) =>
                                                  e.toUpperCase() ==
                                                  _vehicleColorController.text
                                                      .toUpperCase())
                                              : null,
                                      popupProps: PopupProps.menu(
                                          showSearchBox: true,
                                          fit: FlexFit.loose,
                                          constraints: const BoxConstraints(
                                            maxHeight: 325,
                                          ),
                                          itemBuilder:
                                              (context, item, isSelected) {
                                            return DropDownItem(
                                              isSelected:
                                                  _vehicleColorController.text
                                                          .toUpperCase() ==
                                                      item.toUpperCase(),
                                              title: item,
                                            );
                                          }),
                                      onChanged: (value) {
                                        setState(() {
                                          _vehicleColorController.text = value!;
                                        });
                                      },
                                      validator: ((value) {
                                        if (value == null) {
                                          return 'Please select color';
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
                                    child: DropdownSearch<
                                        ContraventionReasonTranslations>(
                                      dropdownBuilder: (context, selectedItem) {
                                        return Text(
                                          selectedItem == null
                                              ? "Select contravention"
                                              : selectedItem.summary as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: selectedItem == null
                                                ? ColorTheme.grey400
                                                : ColorTheme.textPrimary,
                                          ),
                                        );
                                      },
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
                                      selectedItem: fromJsonContraventionList
                                              .isNotEmpty
                                          ? argsFromExpired == null
                                              ? contraventionProvider
                                                          .contravention !=
                                                      null
                                                  ? fromJsonContraventionList
                                                      .firstWhereOrNull((e) =>
                                                          e.contraventionReason
                                                              ?.code ==
                                                          _contraventionReasonController
                                                              .text)
                                                  : null
                                              : argsFromExpired.Type ==
                                                      VehicleInformationType
                                                          .FIRST_SEEN.index
                                                  ? fromJsonContraventionList
                                                      .firstWhereOrNull((e) => e
                                                          .summary!
                                                          .toUpperCase()
                                                          .contains('Overstaying'
                                                              .toUpperCase()))
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
                                      dropdownBuilder: (context, selectedItem) {
                                        return Text(
                                            selectedItem == null
                                                ? "Select zone"
                                                : selectedItem.label,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: selectedItem == null
                                                    ? ColorTheme.grey400
                                                    : ColorTheme.textPrimary));
                                      },
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
                                    style: CustomTextStyle.h5.copyWith(
                                      fontSize: 16,
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                      labelText: "Comment",
                                      hintText: "Enter comment",
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        color: ColorTheme.grey400,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _commentController.text = value;
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
      ),
    );
  }
}

class SelectModel {
  final String label;
  final int value;

  SelectModel({required this.label, required this.value});
}

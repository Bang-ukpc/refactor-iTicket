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
import 'package:iWarden/common/button_scan.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/helpers/contravention_reference_helper.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/providers/car_info_data.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/alert_check_vrn.dart';
import 'package:iWarden/screens/parking-charges/print_issue.dart';
import 'package:iWarden/screens/parking-charges/print_pcn.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
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
  List<EvidencePhoto> evidencePhotoList = [];
  final _debouncer = Debouncer(milliseconds: 300);
  SelectModel? _selectedItemTypePCN;
  List<RotaWithLocation> locationWithRotaList = [];
  List<Contravention> contraventionList = [];
  late ZoneCachedServiceFactory zoneCachedServiceFactory;

  Future<void> getContraventions() async {
    var contraventions = await zoneCachedServiceFactory
        .contraventionCachedService
        .getAllWithCreatedOnTheOffline();
    setState(() {
      contraventionList = contraventions;
    });
  }

  Future<void> getContraventionReasonList() async {
    var contraventionReasons = await zoneCachedServiceFactory
        .contraventionReasonCachedService
        .getAll();
    setState(() {
      contraventionReasonList = contraventionReasons;
    });
  }

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
            locations.onSelectedLocation(value[i].locations![j]);
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

  List<String> arrMake = DataInfoCar().make;
  List<String> arrColor = DataInfoCar().color;

  void onSearchVehicleInfoByPlate(
      String plate, ContraventionProvider contraventionProvider) async {
    showCircularProgressIndicator(context: context);
    try {
      await contraventionController
          .getVehicleDetailByPlate(plate: plate)
          .then((value) {
        if (value?.Make != null) {
          contraventionProvider.setMakeNullProvider(value?.Make);
          setState(() {
            _vehicleMakeController.text = value?.Make ?? '';
          });
        }
        if (value?.Colour != null) {
          contraventionProvider.setColorNullProvider(value?.Colour);
          setState(() {
            _vehicleColorController.text = value?.Colour ?? '';
          });
        }
        Navigator.of(context).pop();
        if (value?.Colour == null && value?.Make == null) {
          CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              "Couldn't find vehicle info",
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
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

  void setContraventionReasons({required bool isOverStaying}) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());

    if (isOverStaying) {
      setState(() {
        contraventionReasonList =
            contraventionReasonList.where((e) => e.code == '36').toList();
      });
    } else {
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        setState(() {
          contraventionReasonList =
              contraventionReasonList.where((e) => e.code != '36').toList();
        });
      } else {
        contraventionReasonList =
            contraventionReasonList.where((e) => e.code != '36').toList();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final vehicleInfo = ModalRoute.of(context)!.settings.arguments as dynamic;
      final locationProvider = Provider.of<Locations>(context, listen: false);
      final contraventionProvider =
          Provider.of<ContraventionProvider>(context, listen: false);
      final wardensProvider = Provider.of<WardensInfo>(context, listen: false);
      zoneCachedServiceFactory = locationProvider.zoneCachedServiceFactory;

      await getContraventionReasonList();

      if (vehicleInfo != null) {
        contraventionProvider.setFirstSeenData(vehicleInfo);
        _vrnController.text = vehicleInfo.Plate;
        if (vehicleInfo.Type == VehicleInformationType.FIRST_SEEN.index) {
          ContraventionReasonTranslations? argsOverstayingTime =
              contraventionReasonList.firstWhereOrNull((e) => e.code == '36');
          _contraventionReasonController.text = argsOverstayingTime != null
              ? argsOverstayingTime.code.toString()
              : '';
          contraventionProvider.setContraventionCode(argsOverstayingTime);
          setContraventionReasons(isOverStaying: true);
        } else {
          setContraventionReasons(isOverStaying: false);
        }
      }

      setContraventionReasons(
          isOverStaying: contraventionProvider.getVehicleInfo?.Type ==
              VehicleInformationType.FIRST_SEEN.index);

      var contraventionData = contraventionProvider.contravention;
      if (contraventionData != null) {
        _vrnController.text = contraventionData.plate ?? '';

        _vehicleMakeController.text =
            contraventionProvider.getMakeNullProvider ?? '';

        _vehicleColorController.text =
            contraventionProvider.getColorNullProvider ?? '';

        _contraventionReasonController.text =
            contraventionProvider.getContraventionCode?.code ?? '';
        if (contraventionProvider.getVehicleInfo != null) {
          if (contraventionProvider.getVehicleInfo?.Type ==
              VehicleInformationType.FIRST_SEEN.index) {
            setContraventionReasons(isOverStaying: true);
          }
        }

        _commentController.text = contraventionData.contraventionEvents!
            .map((item) => item.detail)
            .toString()
            .replaceAll('(', '')
            .replaceAll(')', '');
      }
      setSelectedTypeOfPCN(locationProvider, contraventionData);
      await getLocationList(locationProvider, wardensProvider.wardens?.Id ?? 0)
          .then((value) {
        setSelectedTypeOfPCN(locationProvider, contraventionData);
      });
      getContraventions();
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
    final vehicleInfo = ModalRoute.of(context)!.settings.arguments as dynamic;
    final printIssue = Provider.of<prefix.PrintIssueProviders>(context);

    log('issue pcn screen');

    int randomNumber = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();

    Future<bool> checkDuplicateContravention(
        String contraventionReferenceID) async {
      List<Contravention> issuedContraventions = await zoneCachedServiceFactory
          .contraventionCachedService
          .getAllWithCreatedOnTheOffline();

      bool isContraventionExisted = issuedContraventions.firstWhereOrNull(
              (c) => c.reference == contraventionReferenceID) !=
          null;

      return isContraventionExisted;
    }

    final physicalPCN = ContraventionCreateWardenCommand(
      ZoneId: locationProvider.zone?.Id ?? 0,
      ContraventionReference:
          contraventionReferenceHelper.getContraventionReference(
              prefixNumber: 2, wardenID: wardensProvider.wardens?.Id ?? 0),
      Plate: _vrnController.text,
      VehicleMake: _vehicleMakeController.text,
      VehicleColour: _vehicleColorController.text,
      ContraventionReasonCode:
          contraventionProvider.getContraventionCode?.code ?? '',
      EventDateTime: DateTime.now(),
      FirstObservedDateTime:
          vehicleInfo != null ? vehicleInfo.Created : DateTime.now(),
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
      final physicalPCN2 = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference:
            contraventionReferenceHelper.getContraventionReference(
                prefixNumber: 2, wardenID: wardensProvider.wardens?.Id ?? 0),
        Plate: _vrnController.text,
        VehicleMake: _vehicleMakeController.text,
        VehicleColour: _vehicleColorController.text,
        ContraventionReasonCode: _contraventionReasonController.text,
        EventDateTime: DateTime.now(),
        FirstObservedDateTime:
            vehicleInfo != null ? vehicleInfo.Created : DateTime.now(),
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
      }

      var isVrnExisted = await zoneCachedServiceFactory
          .contraventionCachedService
          .isExistedWithIn24h(
              vrn: physicalPCN.Plate,
              zoneId: physicalPCN.ZoneId,
              contraventionType: physicalPCN.ContraventionReasonCode);
      if (!isVrnExisted) {
        if (!mounted) return;
        showAlertCheckVrnExits(context: context);
        return;
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

      Contravention contravention = Contravention(
        reference: physicalPCN2.ContraventionReference,
        created: DateTime.now(),
        id: physicalPCN2.Id,
        plate: physicalPCN2.Plate,
        colour: physicalPCN2.VehicleColour,
        make: physicalPCN2.VehicleMake,
        eventDateTime: physicalPCN2.EventDateTime,
        zoneId: locationProvider.zone?.Id ?? 0,
        reason: Reason(
          code: physicalPCN2.ContraventionReasonCode,
          contraventionReasonTranslations: contraventionReasonList
              .where((e) => e.code == physicalPCN2.ContraventionReasonCode)
              .toList(),
        ),
        contraventionEvents: [
          ContraventionEvents(
            contraventionId: physicalPCN2.Id,
            detail: physicalPCN2.WardenComments,
          )
        ],
        contraventionDetailsWarden: ContraventionDetailsWarden(
          FirstObserved: physicalPCN2.FirstObservedDateTime,
          ContraventionId: physicalPCN2.Id,
          WardenId: physicalPCN2.WardenId,
          IssuedAt: physicalPCN2.EventDateTime,
        ),
        status: ContraventionStatus.Open.index,
        type: physicalPCN2.TypePCN,
        contraventionPhotos: contraventionImageList,
      );

      bool check = await checkDuplicateContravention(
          physicalPCN2.ContraventionReference);
      if (!mounted) return;
      if (!check) {
        contraventionProvider.upDateContravention(contravention);
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName,
                arguments: {'isPrinter': isPrinter})
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context).pushReplacementNamed(
                    PrintIssue.routeName,
                    arguments: {'isPrinter': isPrinter});
      } else {
        CherryToast.error(
          toastDuration: const Duration(seconds: 3),
          title: Text(
            "Please wait 1 minute to continue to issue pcn",
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }

      _formKey.currentState!.save();
    }

    int randomNumber2 = (DateTime.now().microsecondsSinceEpoch / -1000).ceil();
    final virtualTicket = ContraventionCreateWardenCommand(
      ZoneId: locationProvider.zone?.Id ?? 0,
      ContraventionReference:
          contraventionReferenceHelper.getContraventionReference(
              prefixNumber: 3, wardenID: wardensProvider.wardens?.Id ?? 0),
      Plate: _vrnController.text,
      VehicleMake: _vehicleMakeController.text,
      VehicleColour: _vehicleColorController.text,
      ContraventionReasonCode:
          contraventionProvider.getContraventionCode?.code ?? '',
      EventDateTime: DateTime.now(),
      FirstObservedDateTime:
          vehicleInfo != null ? vehicleInfo.Created : DateTime.now(),
      WardenId: wardensProvider.wardens?.Id ?? 0,
      Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      WardenComments: _commentController.text,
      BadgeNumber: 'test',
      LocationAccuracy: 0, // missing
      TypePCN: TypePCN.Virtual.index,
      Id: randomNumber2,
    );

    Future<void> createVirtualTicket({bool? step2, bool? step3}) async {
      final virtualTicket2 = ContraventionCreateWardenCommand(
        ZoneId: locationProvider.zone?.Id ?? 0,
        ContraventionReference:
            contraventionReferenceHelper.getContraventionReference(
                prefixNumber: 3, wardenID: wardensProvider.wardens?.Id ?? 0),
        Plate: _vrnController.text,
        VehicleMake: _vehicleMakeController.text,
        VehicleColour: _vehicleColorController.text,
        ContraventionReasonCode: _contraventionReasonController.text,
        EventDateTime: DateTime.now(),
        FirstObservedDateTime:
            vehicleInfo != null ? vehicleInfo.Created : DateTime.now(),
        WardenId: wardensProvider.wardens?.Id ?? 0,
        Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        WardenComments: _commentController.text,
        BadgeNumber: 'test',
        LocationAccuracy: 0, // missing
        TypePCN: TypePCN.Virtual.index,
        Id: randomNumber2,
      );
      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      }

      var isVrnExisted = await zoneCachedServiceFactory
          .contraventionCachedService
          .isExistedWithIn24h(
              vrn: virtualTicket.Plate,
              zoneId: virtualTicket.ZoneId,
              contraventionType: virtualTicket.ContraventionReasonCode);
      if (!isVrnExisted) {
        if (!mounted) return;
        showAlertCheckVrnExits(context: context);
        return;
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

      Contravention contravention = Contravention(
        reference: virtualTicket2.ContraventionReference,
        created: DateTime.now(),
        id: virtualTicket2.Id,
        plate: virtualTicket2.Plate,
        colour: virtualTicket2.VehicleColour,
        make: virtualTicket2.VehicleMake,
        eventDateTime: virtualTicket2.EventDateTime,
        zoneId: locationProvider.zone?.Id ?? 0,
        reason: Reason(
          code: virtualTicket2.ContraventionReasonCode,
          contraventionReasonTranslations: contraventionReasonList
              .where((e) => e.code == virtualTicket2.ContraventionReasonCode)
              .toList(),
        ),
        contraventionEvents: [
          ContraventionEvents(
            contraventionId: virtualTicket2.Id,
            detail: virtualTicket2.WardenComments,
          )
        ],
        contraventionDetailsWarden: ContraventionDetailsWarden(
          FirstObserved: virtualTicket2.FirstObservedDateTime,
          ContraventionId: virtualTicket2.Id,
          WardenId: virtualTicket2.WardenId,
          IssuedAt: virtualTicket2.EventDateTime,
        ),
        status: ContraventionStatus.Open.index,
        type: virtualTicket2.TypePCN,
        contraventionPhotos: contraventionImageList,
      );

      bool check = await checkDuplicateContravention(
          virtualTicket2.ContraventionReference);

      if (!mounted) return;
      if (!check) {
        contraventionProvider.upDateContravention(contravention);
        step2 == true
            ? Navigator.of(context).pushReplacementNamed(PrintIssue.routeName)
            : step3 == true
                ? Navigator.of(context).pushReplacementNamed(PrintPCN.routeName)
                : Navigator.of(context)
                    .pushReplacementNamed(PrintIssue.routeName);
      } else {
        CherryToast.error(
          toastDuration: const Duration(seconds: 3),
          title: Text(
            "Please wait 1 minute to continue to issue pcn",
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
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
                                if ((_selectedItemTypePCN?.value ?? 0) == 0) {
                                  createPhysicalPCN(isPrinter: true);
                                } else {
                                  createVirtualTicket();
                                }
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
      await getContraventionReasonList();
      setContraventionReasons(
          isOverStaying: contraventionProvider.getVehicleInfo?.Type ==
              VehicleInformationType.FIRST_SEEN.index);
      var contraventionCodeFind = contraventionReasonList.firstWhereOrNull(
          (e) => e.code == contraventionProvider.getContraventionCode?.code);
      setState(() {
        _contraventionReasonController.text =
            contraventionCodeFind?.contraventionReason?.code ?? "";
      });
      contraventionProvider.setContraventionCode(contraventionCodeFind);
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
                  onPressed: () async {
                    ConnectivityResult connectionStatus =
                        await (Connectivity().checkConnectivity());
                    if (connectionStatus == ConnectivityResult.wifi ||
                        connectionStatus == ConnectivityResult.mobile) {
                      virtualTicket.Plate = _vrnController.text;
                      virtualTicket.WardenComments = _commentController.text;
                      try {
                        if (!mounted) return;
                        showCircularProgressIndicator(context: context);
                        await contraventionController
                            .checkHasPermit(virtualTicket)
                            .then((value) {
                          Navigator.of(context).pop();
                          if (value?.hasPermit == true) {
                            showDialogPermitExists(value);
                          } else {
                            createVirtualTicket();
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
                      createVirtualTicket();
                    }
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
                      physicalPCN.Plate = _vrnController.text;
                      physicalPCN.WardenComments = _commentController.text;
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
                                          enabled: contraventionProvider
                                                  .getVehicleInfo ==
                                              null,
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
                                          onChanged: (value) {
                                            setState(() {});
                                          },
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
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                        ),
                                      ),
                                      Flexible(
                                          flex: 2,
                                          child: ButtonScan(
                                            color:
                                                _vrnController.text.length < 2
                                                    ? ColorTheme.grey300
                                                    : ColorTheme.primary,
                                            onTap: () {
                                              _vrnController.text.length < 2
                                                  ? () {}
                                                  : onSearchVehicleInfoByPlate(
                                                      _vrnController.text,
                                                      contraventionProvider);
                                            },
                                          ))
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
                                          .getMakeNullProvider,
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
                                        contraventionProvider
                                            .setMakeNullProvider(value);
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
                                          .getColorNullProvider,
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
                                        contraventionProvider
                                            .setColorNullProvider(value);
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
                                      enabled: contraventionProvider
                                              .getVehicleInfo?.Type !=
                                          VehicleInformationType
                                              .FIRST_SEEN.index,
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
                                      selectedItem: contraventionProvider
                                          .getContraventionCode,
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
                                              isSelected: item.code ==
                                                  _contraventionReasonController
                                                      .text,
                                              title: item.summary as String,
                                            );
                                          }),
                                      onChanged: (value) {
                                        setState(() {
                                          _contraventionReasonController.text =
                                              value!.code.toString();
                                        });
                                        contraventionProvider
                                            .setContraventionCode(value);
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

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/button_scan.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_info.dart';
import 'package:iWarden/screens/parking-charges/print_pcn.dart';
import 'package:iWarden/screens/scan-plate/anyline_service.dart';
import 'package:iWarden/screens/scan-plate/result.dart';
import 'package:iWarden/screens/scan-plate/scan_modes.dart';
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
  final _vrnController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _contraventionReasonController = TextEditingController();
  final _typeOfPcnController = TextEditingController();
  final _commentController = TextEditingController();
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  int selectedButton = 0;
  List<File> arrayImage = [];
  List<EvidencePhoto> evidencePhotoList = [];
  final _debouncer = Debouncer(milliseconds: 300);

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
    getContraventionReasonList();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
    _vehicleColorController.dispose();
    _typeOfPcnController.dispose();
    _commentController.dispose();
    _contraventionReasonController.dispose();
    if (_debouncer.timer != null) {
      _debouncer.timer!.cancel();
    }
    contraventionReasonList.clear();
    arrayImage.clear();
    evidencePhotoList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    final args = ModalRoute.of(context)!.settings.arguments as dynamic;

    log('Issue PCN screen');

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
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
      final physicalPCN = ContraventionCreateWardenCommand(
        ExternalReference: locationProvider.zone!.ExternalReference,
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
      );

      final wardenEventIssuePCN = WardenEvent(
        type: TypeWardenEvent.IssuePCN.index,
        detail: '{"TicketNumber": "${physicalPCN.ContraventionReference}"}',
        latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        wardenId: wardensProvider.wardens?.Id ?? 0,
        zoneId: locationProvider.zone?.Id ?? 0,
        locationId: locationProvider.location?.Id ?? 0,
        rotaTimeFrom: locationProvider.rotaShift?.timeFrom,
        rotaTimeTo: locationProvider.rotaShift?.timeTo,
      );

      final isValid = _formKey.currentState!.validate();
      Contravention? contravention;
      bool check = false;

      if (arrayImage.isEmpty) {
        if (!mounted) return;
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
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
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
                  filePath: arrayImage[i].path,
                ),
              );
              if (i == arrayImage.length - 1) {
                check = true;
              }
            }
          }
          if (contravention != null && check == true) {
            await userController
                .createWardenEvent(wardenEventIssuePCN)
                .then((value) {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .pushNamed(PrintPCN.routeName, arguments: contravention);
            });
          }
        } on DioError catch (error) {
          log("log ${error.type.toString()}");
          if (!mounted) return;
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
        physicalPCN.Id = randomNumber;
        final String encodedPhysicalPCNData =
            json.encode(ContraventionCreateWardenCommand.toJson(physicalPCN));
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
          if (arrayImage.isNotEmpty) {
            for (int i = 0; i < arrayImage.length; i++) {
              final String encodedData = json.encode(ContraventionCreatePhoto(
                contraventionReference: physicalPCN.ContraventionReference,
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                filePath: arrayImage[i].path,
              ).toJson());
              newPhotoData.add(encodedData);
            }
          }
          final encodedNewData = json.encode(newPhotoData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        } else {
          final createdData =
              json.decode(contraventionPhotoData) as List<dynamic>;
          if (arrayImage.isNotEmpty) {
            for (int i = 0; i < arrayImage.length; i++) {
              final String encodedData = json.encode(ContraventionCreatePhoto(
                contraventionReference: randomNumber.toString(),
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                filePath: arrayImage[i].path,
              ).toJson());
              createdData.add(encodedData);
            }
          }
          final encodedNewData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        }

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

        List<ContraventionPhotos> contraventionImageList = [];
        if (arrayImage.isNotEmpty) {
          for (int i = 0; i < arrayImage.length; i++) {
            contraventionImageList.add(ContraventionPhotos(
              blobName: arrayImage[i].path,
              contraventionId: physicalPCN.Id,
            ));
          }
        }

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
          contraventionPhotos: contraventionImageList,
        );

        final String? contraventionList =
            await SharedPreferencesHelper.getStringValue(
                'contraventionDataLocal');

        if (contraventionList == null) {
          List<dynamic> newData = [];
          newData.add(Contravention.toJson(contraventionDataFake));
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
          fromJsonContravention.rows
              .add(Contravention.toJson(contraventionDataFake));
          final String encodedCreatedData =
              json.encode(Pagination.toJson(fromJsonContravention));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedCreatedData);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context)
            .pushNamed(PrintPCN.routeName, arguments: contraventionDataFake);
      }

      _formKey.currentState!.save();
    }

    Future<void> createVirtualTicket() async {
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      int randomReference =
          (DateTime.now().microsecondsSinceEpoch / 1000).ceil();
      final virtualTicket = ContraventionCreateWardenCommand(
        ExternalReference: locationProvider.zone!.ExternalReference,
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

      final isValid = _formKey.currentState!.validate();
      Contravention? contravention;
      bool check = false;

      if (arrayImage.isEmpty) {
        if (!mounted) return;
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
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
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
                  filePath: arrayImage[i].path,
                ),
              );
              if (i == arrayImage.length - 1) {
                check = true;
              }
            }
          }
          if (contravention != null && check == true) {
            await userController
                .createWardenEvent(wardenEventIssuePCN)
                .then((value) {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                ParkingChargeInfo.routeName,
                arguments: contravention,
              );
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
          if (arrayImage.isNotEmpty) {
            for (int i = 0; i < arrayImage.length; i++) {
              final String encodedData = json.encode(ContraventionCreatePhoto(
                contraventionReference: virtualTicket.ContraventionReference,
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                filePath: arrayImage[i].path,
              ).toJson());
              newPhotoData.add(encodedData);
            }
          }
          final encodedNewData = json.encode(newPhotoData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        } else {
          final createdData =
              json.decode(contraventionPhotoData) as List<dynamic>;
          if (arrayImage.isNotEmpty) {
            for (int i = 0; i < arrayImage.length; i++) {
              final String encodedData = json.encode(ContraventionCreatePhoto(
                contraventionReference: randomNumber.toString(),
                originalFileName: arrayImage[i].path.split('/').last,
                capturedDateTime: DateTime.now(),
                filePath: arrayImage[i].path,
              ).toJson());
              createdData.add(encodedData);
            }
          }
          final encodedNewData = json.encode(createdData);
          SharedPreferencesHelper.setStringValue(
              'contraventionPhotoDataLocal', encodedNewData);
        }

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

        List<ContraventionPhotos> contraventionImageList = [];
        if (arrayImage.isNotEmpty) {
          for (int i = 0; i < arrayImage.length; i++) {
            contraventionImageList.add(ContraventionPhotos(
              blobName: arrayImage[i].path,
              contraventionId: virtualTicket.Id,
            ));
          }
        }

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
          contraventionPhotos: contraventionImageList,
        );

        final String? contraventionList =
            await SharedPreferencesHelper.getStringValue(
                'contraventionDataLocal');

        if (contraventionList == null) {
          List<dynamic> newData = [];
          newData.add(Contravention.toJson(contraventionDataFake));
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
          fromJsonContravention.rows
              .add(Contravention.toJson(contraventionDataFake));
          final String encodedCreatedData =
              json.encode(Pagination.toJson(fromJsonContravention));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedCreatedData);
        }

        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(
          ParkingChargeInfo.routeName,
          arguments: contraventionDataFake,
        );
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
              Navigator.of(context).pop();
            },
          ),
          drawer: const MyDrawer(),
          bottomNavigationBar: BottomSheet2(
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
                            child:
                                DropdownSearch<ContraventionReasonTranslations>(
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: dropDownButtonStyle
                                    .getInputDecorationCustom(
                                  labelText: const LabelRequire(
                                    labelText: 'Contravention',
                                  ),
                                  hintText: 'Select contravention',
                                ),
                              ),
                              items: contraventionReasonList,
                              itemAsString: (item) => item.summary as String,
                              popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  fit: FlexFit.loose,
                                  constraints: const BoxConstraints(
                                    maxHeight: 325,
                                  ),
                                  itemBuilder: (context, item, isSelected) {
                                    return DropDownItem(
                                      isSelected: item
                                              .contraventionReason!.code ==
                                          _contraventionReasonController.text,
                                      title: item.summary as String,
                                    );
                                  }),
                              onChanged: (value) {
                                setState(() {
                                  _contraventionReasonController.text = value!
                                      .contraventionReason!.code
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
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: dropDownButtonStyle
                                    .getInputDecorationCustom(
                                  labelText: const LabelRequire(
                                    labelText: 'Type of PCN',
                                  ),
                                  hintText: 'Select type of PCN',
                                ),
                              ),
                              items: typeOfPCN,
                              selectedItem: typeOfPCN[0],
                              itemAsString: (item) => item.label,
                              popupProps: PopupProps.menu(
                                fit: FlexFit.loose,
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                itemBuilder: (context, item, isSelected) =>
                                    DropDownItem(
                                  isSelected: item.value.toString() ==
                                      _typeOfPcnController.text,
                                  title: item.label,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _typeOfPcnController.text =
                                      value!.value.toString();
                                });
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
                  ),
                  AddImage(
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

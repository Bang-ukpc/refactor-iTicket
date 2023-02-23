import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/id_helper.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/abort-screen/abort_screen.dart';
import 'package:iWarden/screens/parking-charges/pcn_information/parking_charge_info.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';
import 'package:iWarden/services/local/issued_pcn_local_service.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

import '../../services/local/created_warden_event_local_service .dart';
import '../../widgets/parking-charge/detail_parking_common2.dart';

class PrintPCN extends StatefulWidget {
  static const routeName = '/print-pcn';
  const PrintPCN({super.key});

  @override
  State<PrintPCN> createState() => _PrintPCNState();
}

class _PrintPCNState extends State<PrintPCN> {
  @override
  Widget build(BuildContext context) {
    final contraventionProvider = Provider.of<ContraventionProvider>(context);
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    var args = contraventionProvider.contravention;
    final printIssue = Provider.of<PrintIssueProviders>(context);
    var zoneCachedServiceFactory = locationProvider.zoneCachedServiceFactory;

    print('[CONTRAVENTION REFERENCE] ${args?.reference}');

    final contraventionCreate = ContraventionCreateWardenCommand(
      ZoneId: args?.zoneId ?? 0,
      ContraventionReference: args?.reference ?? "",
      Plate: args?.plate ?? "",
      VehicleMake: contraventionProvider.getMakeNullProvider ?? "",
      VehicleColour: contraventionProvider.getColorNullProvider ?? "",
      ContraventionReasonCode:
          contraventionProvider.getContraventionCode?.code ?? "",
      EventDateTime: DateTime.now(),
      FirstObservedDateTime:
          args?.contraventionDetailsWarden?.FirstObserved ?? DateTime.now(),
      WardenId: args?.contraventionDetailsWarden?.WardenId ?? 0,
      Latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      Longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      WardenComments: args != null
          ? args.contraventionEvents!.isNotEmpty
              ? args.contraventionEvents!
                  .map((item) => item.detail)
                  .toString()
                  .replaceAll('(', '')
                  .replaceAll(')', '')
              : ''
          : '',
      BadgeNumber: 'test',
      LocationAccuracy: 0, // missing
      TypePCN: args != null ? args.type : 1,
    );

    Future<void> onRemoveFromVehicleInfo() async {
      if (contraventionProvider.getVehicleInfo != null) {
        var vehicleInfo =
            contraventionProvider.getVehicleInfo as VehicleInformation;
        await createdVehicleDataLocalService.onCarLeft(vehicleInfo);
      }
      return;
    }

    Future<void> issuePCN() async {
      await issuedPcnLocalService.create(contraventionCreate);

      var images = args!.contraventionPhotos!
          .map(
            (e) => ContraventionCreatePhoto(
              Id: idHelper.generateId(),
              contraventionReference:
                  contraventionCreate.ContraventionReference,
              originalFileName: e.blobName!.split('/').last,
              capturedDateTime: DateTime.now(),
              filePath: e.blobName as String,
              photoType: args.type == TypePCN.Physical.index ? 5 : 6,
            ),
          )
          .toList();

      await issuedPcnPhotoLocalService.bulkCreate(images);

      await onRemoveFromVehicleInfo().then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(ParkingChargeInfo.routeName,
            arguments: contraventionProvider.contravention);
        CherryToast.success(
          displayCloseButton: false,
          title: Text(
            'The PCN has been created successfully',
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
        contraventionProvider.clearContraventionData();
        printIssue.resetData();
      });
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        drawer: const MyDrawer(),
        bottomNavigationBar: Consumer<Locations>(
          builder: (context, locations, child) => BottomSheet2(
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
                label: 'Abort',
              ),
              BottomNavyBarItem(
                onPressed: () async {
                  showCircularProgressIndicator(context: context);
                  issuePCN();
                },
                icon: SvgPicture.asset(
                  'assets/svg/IconComplete2.svg',
                ),
                label: 'Complete',
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: DetailParkingCommon2(
            contravention: args,
          ),
        ),
      ),
    );
  }
}

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/custom_checkbox.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/sync-zone-data/sync_zone_data_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../services/local/created_warden_event_local_service .dart';

class ReadRegulationScreen extends StatefulWidget {
  static const routeName = '/read-regulation';
  const ReadRegulationScreen({super.key});

  @override
  State<ReadRegulationScreen> createState() => _ReadRegulationScreenState();
}

class _ReadRegulationScreenState extends State<ReadRegulationScreen> {
  bool checkbox = false;

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context);
    final wardersProvider = Provider.of<WardensInfo>(context);

    log('Read regulation screen');

    WardenEvent wardenEvent = WardenEvent(
      type: TypeWardenEvent.CheckIn.index,
      detail: 'Warden checked in',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardersProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    void checkNextPage() async {
      // eventAnalytics.clickButton(
      //   button: "Check in",
      //   user: wardersProvider.wardens!.Email,
      // );
      if (locations.location?.Notes?.isEmpty == true ||
          locations.location?.Notes == null) {
        try {
          showCircularProgressIndicator(context: context, text: 'Checking in');
          await createdWardenEventLocalService
              .create(wardenEvent)
              .then((value) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
                SyncZoneData.routeName, (Route<dynamic> route) => false);
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
        }
      } else {
        if (!mounted) return;
        if (!checkbox) {
          CherryToast.error(
            displayCloseButton: false,
            title: Text(
              'Please tick to confirm and go next',
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        } else {
          try {
            showCircularProgressIndicator(
                context: context, text: 'Checking in');
            await createdWardenEventLocalService
                .create(wardenEvent)
                .then((value) {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  SyncZoneData.routeName, (Route<dynamic> route) => false);
            });
          } on DioError catch (error) {
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
          }
        }
      }
    }

    Color buttonBackground() {
      if (locations.location?.Notes?.isEmpty == true ||
          locations.location?.Notes == null) {
        return ColorTheme.primary;
      } else {
        if (checkbox) {
          return ColorTheme.primary;
        } else {
          return ColorTheme.grey400;
        }
      }
    }

    return Scaffold(
      bottomSheet: SizedBox(
        height: 46,
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              buttonBackground(),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: locations.location?.Notes?.isEmpty ?? true
              ? checkNextPage
              : checkbox == true
                  ? checkNextPage
                  : null,
          icon: SvgPicture.asset('assets/svg/IconNextBottom.svg'),
          label: Text(
            'Check in',
            style:
                CustomTextStyle.h6.copyWith(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 60,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "Please read below and confirm that you understand all regulations of this location.",
                          style: CustomTextStyle.h4.copyWith(
                              color: ColorTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          locations.location?.Notes?.isEmpty ?? true
                              ? "This location does not currently have any regulations!"
                              : locations.location?.Notes as String,
                          style: CustomTextStyle.h4
                              .copyWith(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  if (locations.location?.Notes?.isEmpty == false ||
                      locations.location?.Notes != null)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: CustomCheckBox(
                        value: checkbox,
                        onChanged: (val) {
                          setState(() {
                            checkbox = val;
                          });
                        },
                        title:
                            "I confirm that I already read and understood every regulations.",
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

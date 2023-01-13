import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class StartBreakScreen extends StatefulWidget {
  static const routeName = 'start-break';
  const StartBreakScreen({super.key});

  @override
  State<StartBreakScreen> createState() => _StartBreakScreenState();
}

class _StartBreakScreenState extends State<StartBreakScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final wardersProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);

    WardenEvent wardenEventEndBreak = WardenEvent(
      type: TypeWardenEvent.EndBreak.index,
      detail: 'Warden has end break',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardersProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    void onEndBreak() async {
      try {
        await userController
            .createWardenEvent(wardenEventEndBreak)
            .then((value) {
          Navigator.of(context).pushReplacementNamed(HomeOverview.routeName);
        });
      } on DioError catch (error) {
        if (error.type == DioErrorType.other) {
          CherryToast.error(
            toastDuration: const Duration(seconds: 2),
            title: Text(
              'Network error',
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        CherryToast.error(
          displayCloseButton: false,
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
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        width: screenWidth,
        height: screenHeight,
        color: ColorTheme.primary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You are on break',
                style: CustomTextStyle.h3.copyWith(
                  decoration: TextDecoration.none,
                  color: ColorTheme.white,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton.icon(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    ColorTheme.grey300,
                  ),
                ),
                onPressed: onEndBreak,
                icon: SvgPicture.asset(
                  "assets/svg/IconEndBreak.svg",
                  color: ColorTheme.textPrimary,
                ),
                label: const Text(
                  'End break',
                  style: CustomTextStyle.body1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

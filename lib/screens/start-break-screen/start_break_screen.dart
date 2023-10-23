import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../../helpers/my_navigator_observer.dart';
import '../../services/local/created_warden_event_local_service .dart';

class StartBreakScreen extends StatefulWidget {
  static const routeName = 'start-break';
  const StartBreakScreen({super.key});

  @override
  BaseStatefulState<StartBreakScreen> createState() => _StartBreakScreenState();
}

class _StartBreakScreenState extends BaseStatefulState<StartBreakScreen> {
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
      showCircularProgressIndicator(context: context);
      await createdWardenEventLocalService
          .create(wardenEventEndBreak)
          .then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(HomeOverview.routeName);
      });
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        bottomNavigationBar: const VersionName(),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          width: screenWidth,
          height: screenHeight,
          color: ColorTheme.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: ColorTheme.lighterSecondary,
                    borderRadius: BorderRadius.circular(40)),
                child: SvgPicture.asset(
                  "assets/svg/IconStartBreak.svg",
                  height: 32,
                  width: 32,
                  color: ColorTheme.secondary,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Column(
                children: [
                  Text(
                    'You are on break. \nPlease click End break to start again.',
                    style: CustomTextStyle.h4.copyWith(
                      color: ColorTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              InkWell(
                onTap: onEndBreak,
                child: Container(
                  height: 40,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorTheme.secondary,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "End break",
                        style: TextStyle(
                          color: ColorTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        "assets/svg/IconEndBreak.svg",
                        height: 18,
                        width: 18,
                        color: ColorTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/custom_checkbox.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/index.dart';
import 'package:iWarden/helpers/alert_helper.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/sync-zone-data/sync_zone_data_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../helpers/my_navigator_observer.dart';
import '../services/local/created_warden_event_local_service .dart';

class ReadRegulationScreen extends StatefulWidget {
  static const routeName = '/read-regulation';
  const ReadRegulationScreen({super.key});

  @override
  BaseStatefulState<ReadRegulationScreen> createState() =>
      _ReadRegulationScreenState();
}

class _ReadRegulationScreenState
    extends BaseStatefulState<ReadRegulationScreen> {
  bool checkbox = false;

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<Locations>(context);
    final wardersProvider = Provider.of<WardensInfo>(context);

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
      DateTime now = await timeNTP.get();
      if (locations.location?.Notes?.isEmpty == true ||
          locations.location?.Notes == null) {
        wardenEvent.Created ??= now;
        if (!mounted) return;
        showCircularProgressIndicator(context: context, text: 'Checking in');
        weakNetworkUserController.createWardenEvent(wardenEvent).then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamedAndRemoveUntil(
              SyncZoneData.routeName, (Route<dynamic> route) => false);
        }).catchError((error) async {
          Navigator.of(context).pop();
          await createdWardenEventLocalService.create(wardenEvent);
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
              SyncZoneData.routeName, (Route<dynamic> route) => false);
        });
      } else {
        if (!checkbox) {
          if (!mounted) return;
          alertHelper.error("Please tick to confirm and go next");
        } else {
          wardenEvent.Created ??= now;
          if (!mounted) return;
          showCircularProgressIndicator(context: context, text: 'Checking in');
          weakNetworkUserController
              .createWardenEvent(wardenEvent)
              .then((value) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
                SyncZoneData.routeName, (Route<dynamic> route) => false);
          }).catchError((error) async {
            Navigator.of(context).pop();
            await createdWardenEventLocalService.create(wardenEvent);
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
                SyncZoneData.routeName, (Route<dynamic> route) => false);
          });
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
      bottomNavigationBar: const VersionName(),
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class InfoDrawer extends StatelessWidget {
  final String name;
  final String assetImage;
  final String? location;
  final String? zone;
  final bool isDrawer;
  const InfoDrawer(
      {Key? key,
      required this.assetImage,
      required this.name,
      required this.isDrawer,
      this.location,
      this.zone})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wardersProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);

    WardenEvent wardenEvent = WardenEvent(
      type: TypeWardenEvent.CheckOut.index,
      detail: 'Warden checked out',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardersProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
    );

    void onCheckOut() async {
      try {
        await userController.createWardenEvent(wardenEvent).then((value) {
          Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
        });
      } catch (error) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            'Check out error, please try again',
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

    buildAvatar() {
      if (isDrawer) {
        return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                border: Border.all(
                    width: 8, color: const Color.fromRGBO(255, 255, 255, 0.1)),
                borderRadius: BorderRadius.circular(30)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                assetImage,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/userAvatar.png'),
                fit: BoxFit.cover,
              ),
            ));
      } else {
        return Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          // decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
          //   BoxShadow(
          //       color: ColorTheme.grey600, blurRadius: 0, spreadRadius: -2.5),
          //   BoxShadow(
          //     color: Colors.white,
          //     offset: Offset(-10, 15),
          //     blurRadius: 18,
          //     spreadRadius: 18,
          //   ),
          // ]),
          child: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                assetImage,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/images/userAvatar.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: !isDrawer
              ? (zone == null && location == null)
                  ? 5
                  : 16
              : 37,
          bottom: !isDrawer
              ? (zone == null && location == null)
                  ? 5
                  : 16
              : 15,
        ),
        color: isDrawer ? ColorTheme.darkPrimary : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildAvatar(),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CustomTextStyle.h6.copyWith(
                        color:
                            !isDrawer ? ColorTheme.textPrimary : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    if (location != null)
                      Text(
                        "Location: ${location!}",
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.caption.copyWith(
                            color: !isDrawer
                                ? ColorTheme.textPrimary
                                : Colors.white),
                      ),
                    if (zone != null)
                      Text(
                        "Zone: ${zone!}",
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.caption.copyWith(
                            color: !isDrawer
                                ? ColorTheme.textPrimary
                                : Colors.white),
                      ),
                  ],
                )
              ],
            ),
            if (isDrawer)
              const SizedBox(
                height: 5,
              ),
            if (isDrawer)
              Container(
                margin: const EdgeInsets.only(left: 65),
                height: 26,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ElevatedButton.icon(
                    icon: SvgPicture.asset(
                      "assets/svg/IconEndShift.svg",
                      width: 12,
                      color: ColorTheme.textPrimary,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ColorTheme.secondary,
                    ),
                    label: const Text(
                      "Check out",
                      style: CustomTextStyle.h6,
                    ),
                    onPressed: onCheckOut,
                  ),
                ),
              )
          ],
        ));
  }
}

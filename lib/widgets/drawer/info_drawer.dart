import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/circle.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
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
      ConnectivityResult connectionStatus =
          await (Connectivity().checkConnectivity());
      if (connectionStatus == ConnectivityResult.wifi ||
          connectionStatus == ConnectivityResult.mobile) {
        try {
          await userController.createWardenEvent(wardenEvent).then((value) {
            Navigator.of(context)
                .pushReplacementNamed(LocationScreen.routeName);
          });
        } on DioError catch (error) {
          if (error.type == DioErrorType.other) {
            // ignore: use_build_context_synchronously
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
          // ignore: use_build_context_synchronously
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
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
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
                borderRadius: BorderRadius.circular(100)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: assetImage,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    Center(
                  child: Center(
                    child: SpinKitCircle(
                      color: ColorTheme.primary,
                      size: 25,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/images/userAvatar.png'),
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
              borderRadius: BorderRadius.circular(100),
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
                      style: CustomTextStyle.h5.copyWith(
                        color:
                            !isDrawer ? ColorTheme.textPrimary : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (location != null)
                      Text(
                        "Location: ${location!}",
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.body2.copyWith(
                            color: !isDrawer
                                ? ColorTheme.textPrimary
                                : Colors.white),
                      ),
                    if (zone != null)
                      Text(
                        "Zone: ${zone!}",
                        overflow: TextOverflow.ellipsis,
                        style: CustomTextStyle.body2.copyWith(
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

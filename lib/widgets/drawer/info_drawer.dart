import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class InfoDrawer extends StatelessWidget {
  final String name;
  final String assetImage;
  final String? location;
  final String? zone;
  final bool isDrawer;
  final bool isLogout;
  const InfoDrawer({
    Key? key,
    required this.assetImage,
    required this.name,
    required this.isDrawer,
    this.location,
    this.zone,
    this.isLogout = false,
  }) : super(key: key);

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
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    void onCheckOut() async {
      try {
        displayLoading(context: context, text: 'Checking out');
        await userController.createWardenEvent(wardenEvent).then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
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
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
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
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

    void onLogout(Auth auth) async {
      try {
        await auth.logout().then((value) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              LoginScreen.routeName, (Route<dynamic> route) => false);
          CherryToast.success(
            displayCloseButton: false,
            title: Text(
              'Log out successfully',
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.success),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        });
      } on DioError catch (error) {
        if (error.type == DioErrorType.other) {
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
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      color: ColorTheme.primary,
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
          //     blurRadius: 20,
          //     spreadRadius: 20,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                      SizedBox(
                        width: isLogout == true
                            ? MediaQuery.of(context).size.width * 0.4
                            : MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          name,
                          style: CustomTextStyle.h5.copyWith(
                            color: !isDrawer
                                ? ColorTheme.textPrimary
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
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
          ),
          if (isLogout == true)
            Consumer<Auth>(
              builder: (context, auth, _) {
                return ElevatedButton(
                  onPressed: () {
                    onLogout(auth);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: ColorTheme.lightDanger,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Log out",
                        style: CustomTextStyle.h6.copyWith(
                            color: ColorTheme.danger,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SvgPicture.asset(
                        "assets/svg/IconEndShift.svg",
                        width: 18,
                        color: ColorTheme.danger,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

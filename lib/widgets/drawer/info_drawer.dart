import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/check_background_service_status_helper.dart';
import 'package:iWarden/helpers/check_turn_on_net_work.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/helpers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/auth/login_screen.dart';
import 'package:iWarden/screens/syncing-data-logs/syncing_data_log_screen.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/display_alert.dart';
import 'package:provider/provider.dart';

enum EventAction { logout }

class InfoDrawer extends StatefulWidget {
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
  State<InfoDrawer> createState() => _InfoDrawerState();
}

class _InfoDrawerState extends State<InfoDrawer> {
  bool isValidImage = false;

  Future<bool> checkImageLinkValidity(String imageUrl) async {
    final DefaultCacheManager cacheManager = DefaultCacheManager();
    try {
      await cacheManager.getSingleFile(imageUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final syncData = Provider.of<SyncData>(context, listen: false);
      await syncData.getQuantity();
      bool checkImageLinkValid =
          await checkImageLinkValidity(widget.assetImage);
      setState(() {
        isValidImage = checkImageLinkValid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final wardersProvider = Provider.of<WardensInfo>(context);
    final syncData = Provider.of<SyncData>(context);
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
      showCircularProgressIndicator(context: context, text: 'Checking out');
      await createdWardenEventLocalService.create(wardenEvent).then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
      });
    }

    Future onLogout() async {
      await syncData.getQuantity();
      if (syncData.totalDataNeedToSync > 0) {
        if (await checkTurnOnNetWork.turnOnWifiAndMobile()) {
          if (await checkBackgroundServiceStatusHelper.isRunning()) {
            if (!mounted) return;
            openAlert(
              context: context,
              content:
                  'Data is being synced. Please waiting until it’s done. Thank you.',
              textButton: 'I got it',
            );
          } else {
            if (syncData.isSyncing) {
              if (!mounted) return;
              openAlert(
                context: context,
                content:
                    'Data is being synced. Please waiting until it’s done. Thank you.',
                textButton: 'I got it',
              );
            } else {
              if (mounted) {
                openAlertWithAction(
                  context: context,
                  title: 'Sync before logout',
                  content:
                      'You still have some data that needs to be synced. Please sync before you logout.\n\nThe total data waiting for synchronization: ${syncData.totalDataNeedToSync}',
                  textButton: 'Sync now',
                  action: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      SyncingDataLogScreen.routeName,
                      (Route<dynamic> route) => false,
                      arguments: {'action': EventAction.logout.index},
                    );
                  },
                );
              }
            }
          }
        } else {
          if (!mounted) return;
          openAlert(
            context: context,
            content:
                'There is currently no internet connection. Please connect to the internet to synchronize the data before logging out. Thank you.',
            textButton: 'I got it',
          );
        }
      } else {
        if (!mounted) return;
        showCircularProgressIndicator(context: context, text: "Logging out");
        await authentication.logout().then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamedAndRemoveUntil(
              LoginScreen.routeName, (Route<dynamic> route) => false);
          CherryToast.success(
            displayCloseButton: false,
            title: Text(
              'Log out successfully',
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        });
      }
    }

    buildAvatar() {
      if (widget.isDrawer) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              border: Border.all(
                  width: 8, color: const Color.fromRGBO(255, 255, 255, 0.1)),
              borderRadius: BorderRadius.circular(100)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: isValidImage
                ? CachedNetworkImage(
                    imageUrl: widget.assetImage,
                    fit: BoxFit.cover,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          color: ColorTheme.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/userAvatar.png',
                      cacheWidth: 80,
                      cacheHeight: 80,
                    ),
                  )
                : Image.asset(
                    'assets/images/userAvatar.png',
                    cacheWidth: 80,
                    cacheHeight: 80,
                  ),
          ),
        );
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
              child: isValidImage
                  ? CachedNetworkImage(
                      imageUrl: widget.assetImage,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            color: ColorTheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/userAvatar.png',
                        cacheWidth: 80,
                        cacheHeight: 80,
                      ),
                    )
                  : Image.asset(
                      'assets/images/userAvatar.png',
                      cacheWidth: 80,
                      cacheHeight: 80,
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
        top: !widget.isDrawer
            ? (widget.zone == null && widget.location == null)
                ? 5
                : 16
            : 37,
        bottom: !widget.isDrawer
            ? (widget.zone == null && widget.location == null)
                ? 5
                : 16
            : 15,
      ),
      color: widget.isDrawer ? ColorTheme.darkPrimary : Colors.white,
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
                        width: widget.isLogout == true
                            ? MediaQuery.of(context).size.width * 0.4
                            : MediaQuery.of(context).size.width * 0.5,
                        child: Text(
                          widget.name,
                          style: CustomTextStyle.h5.copyWith(
                            color: !widget.isDrawer
                                ? ColorTheme.textPrimary
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (widget.location != null)
                        SizedBox(
                          width: widget.isLogout == true
                              ? MediaQuery.of(context).size.width * 0.4
                              : MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            "Location: ${widget.location!}",
                            style: CustomTextStyle.body2.copyWith(
                              color: !widget.isDrawer
                                  ? ColorTheme.textPrimary
                                  : Colors.white,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (widget.zone != null)
                        SizedBox(
                          width: widget.isLogout == true
                              ? MediaQuery.of(context).size.width * 0.4
                              : MediaQuery.of(context).size.width * 0.5,
                          child: Text(
                            "Zone: ${widget.zone!}",
                            style: CustomTextStyle.body2.copyWith(
                              color: !widget.isDrawer
                                  ? ColorTheme.textPrimary
                                  : Colors.white,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
              if (widget.isDrawer)
                const SizedBox(
                  height: 5,
                ),
              if (widget.isDrawer)
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
                        style: CustomTextStyle.h5,
                      ),
                      onPressed: onCheckOut,
                    ),
                  ),
                )
            ],
          ),
          if (widget.isLogout == true)
            ElevatedButton(
              onPressed: () {
                onLogout();
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
                    style: CustomTextStyle.h5.copyWith(
                        color: ColorTheme.danger, fontWeight: FontWeight.w400),
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
            ),
        ],
      ),
    );
  }
}

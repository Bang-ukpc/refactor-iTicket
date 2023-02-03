import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/bluetooth_printer.dart';
import 'package:iWarden/helpers/debouncer.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/start-break-screen/start_break_screen.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/model/data.dart';
import 'package:iWarden/widgets/drawer/model/menu_item.dart';
import 'package:iWarden/widgets/drawer/model/nav_item.dart';
import 'package:iWarden/widgets/drawer/nav_item.dart';
import 'package:iWarden/widgets/drawer/spot_check.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/color.dart';
import 'info_drawer.dart';
import 'item_menu_widget.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool check = false;
  final _debouncer = Debouncer(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    bluetoothPrinterHelper.scan();
    bluetoothPrinterHelper.initConnect(isLoading: true);
  }

  @override
  void dispose() {
    bluetoothPrinterHelper.disposePrinter();
    if (_debouncer.timer != null) {
      _debouncer.timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heightScreen = MediaQuery.of(context).size.height;
    final widthScreen = MediaQuery.of(context).size.width;
    final wardensProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);

    WardenEvent wardenEventStartBreak = WardenEvent(
      type: TypeWardenEvent.StartBreak.index,
      detail: 'Warden has begun to rest',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    WardenEvent wardenEventCheckOut = WardenEvent(
      type: TypeWardenEvent.CheckOut.index,
      detail: 'Warden checked out',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    WardenEvent wardenEventEndShift = WardenEvent(
      type: TypeWardenEvent.EndShift.index,
      detail: 'Warden has ended shift',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
      rotaTimeFrom: locations.rotaShift?.timeFrom,
      rotaTimeTo: locations.rotaShift?.timeTo,
    );

    void onStartBreak() async {
      try {
        showCircularProgressIndicator(context: context);
        await userController
            .createWardenEvent(wardenEventStartBreak)
            .then((value) {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(StartBreakScreen.routeName);
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

    void onEndShift(Auth auth) async {
      try {
        showCircularProgressIndicator(context: context);
        await userController
            .createWardenEvent(wardenEventCheckOut)
            .then((value) async {
          await userController
              .createWardenEvent(wardenEventEndShift)
              .then((value) async {
            final service = FlutterBackgroundService();
            var isRunning = await service.isRunning();
            if (isRunning) {
              service.invoke("stopService");
            }
            SharedPreferencesHelper.removeStringValue(
                'rotaShiftSelectedByWarden');
            SharedPreferencesHelper.removeStringValue(
                'locationSelectedByWarden');
            SharedPreferencesHelper.removeStringValue('zoneSelectedByWarden');
            if (!mounted) return;
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
                ConnectingScreen.routeName, (Route<dynamic> route) => false,
                arguments: 'check-out');
          });
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

    List<Widget> getList() {
      return DataMenuItem()
          .data
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ItemMenuWidget(
                itemMenu: e,
                onTap: e.route == 'coming soon'
                    ? () {
                        Navigator.of(context).pop();
                        CherryToast.info(
                          displayCloseButton: false,
                          title: Text(
                            'Coming soon',
                            style: CustomTextStyle.h4
                                .copyWith(color: ColorTheme.secondary),
                          ),
                          toastPosition: Position.bottom,
                          borderRadius: 5,
                        ).show(context);
                      }
                    : e.route == 'testPrinter'
                        ? () async {
                            if (bluetoothPrinterHelper.selectedPrinter ==
                                null) {
                              showCircularProgressIndicator(
                                context: context,
                                text: 'Connecting to printer',
                              );
                              _debouncer.run(() {
                                Navigator.of(context).pop();
                                CherryToast.error(
                                  toastDuration: const Duration(seconds: 5),
                                  title: Text(
                                    "Can't connect to a printer. Enable Bluetooth on both mobile device and printer and check that devices are paired.",
                                    style: CustomTextStyle.h4
                                        .copyWith(color: ColorTheme.danger),
                                  ),
                                  toastPosition: Position.bottom,
                                  borderRadius: 5,
                                ).show(context);
                              });
                            } else {
                              showCircularProgressIndicator(
                                  context: context,
                                  text: 'Connecting to printer');
                              bluetoothPrinterHelper.printReceiveTest();
                            }
                          }
                        : () => Navigator.of(context).pushReplacementNamed(
                              e.route!,
                            ),
              ),
            ),
          )
          .toList();
    }

    List<NavItemMenu> navItem = [
      NavItemMenu(
        title: '999',
        icon: SvgPicture.asset('assets/svg/IconCall3.svg'),
        route: HomeOverview.routeName,
        background: ColorTheme.grey200,
        check: null,
        setCheck: () async {
          final call = Uri.parse('tel:999');
          if (await canLaunchUrl(call)) {
            launchUrl(call);
          } else {
            throw 'Could not launch $call';
          }
        },
      ),
      NavItemMenu(
        title: 'Start break',
        icon: SvgPicture.asset('assets/svg/IconStartBreak.svg'),
        route: HomeOverview.routeName,
        check: true,
        background: ColorTheme.lighterSecondary,
        setCheck: onStartBreak,
      ),
    ];
    List<Widget> getListNav() {
      return navItem
          .map((e) => NavItem(
                itemMenu: e,
              ))
          .toList();
    }

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    Widget containerDrawer(Widget children) {
      if (isLandscape) {
        return SingleChildScrollView(child: children);
      } else {
        return children;
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SizedBox(
          width: isLandscape ? widthScreen * 0.66 : widthScreen * 0.85,
          child: Drawer(
            child: containerDrawer(Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: [
                    Container(
                      height: 150,
                      margin: const EdgeInsets.only(top: 5),
                      child: InfoDrawer(
                        isDrawer: true,
                        assetImage: wardensProvider.wardens?.Picture ??
                            "assets/images/userAvatar.png",
                        name: "Hi ${wardensProvider.wardens?.FullName ?? ""}",
                        location: locations.location?.Name ?? 'Empty name',
                        zone: locations.zone?.Name ?? 'Empty name',
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: getList(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: SpotCheck(),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Consumer<Auth>(
                      builder: (context, auth, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ItemMenuWidget(
                            itemMenu: ItemMenu(
                              "End shift",
                              'assets/svg/IconEndShift.svg',
                              null,
                            ),
                            onTap: () {
                              onEndShift(auth);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // SizedBox(height: heightScreen / 3.5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: getListNav(),
                  ),
                ),
              ],
            )),
          )),
    );
  }
}

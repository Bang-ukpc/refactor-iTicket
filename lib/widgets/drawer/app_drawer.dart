import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/dot.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/bluetooth_printer.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/login_screens.dart';
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

  @override
  void initState() {
    super.initState();
    bluetoothPrinterHelper.scan();
    bluetoothPrinterHelper.initConnect(isLoading: true);
  }

  @override
  void dispose() {
    bluetoothPrinterHelper.disposePrinter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heightScreen = MediaQuery.of(context).size.height;
    final widthScreen = MediaQuery.of(context).size.width;
    final wardensProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);

    void showLoading() {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: ColorTheme.mask,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Connecting to printer',
                        style: CustomTextStyle.h4.copyWith(
                          decoration: TextDecoration.none,
                          color: ColorTheme.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 2),
                        child: const SpinKitThreeBounce(
                          color: ColorTheme.white,
                          size: 7,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    WardenEvent wardenEventStartBreak = WardenEvent(
      type: TypeWardenEvent.StartBreak.index,
      detail: 'Warden has begun to rest',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
    );

    WardenEvent wardenEventEndShift = WardenEvent(
      type: TypeWardenEvent.EndShift.index,
      detail: 'Warden has ended shift',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
      zoneId: locations.zone?.Id ?? 0,
      locationId: locations.location?.Id ?? 0,
    );

    void onStartBreak() async {
      try {
        await userController
            .createWardenEvent(wardenEventStartBreak)
            .then((value) {
          Navigator.of(context).pushNamed(StartBreakScreen.routeName);
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

    void onEndShift(Auth auth) async {
      try {
        await userController
            .createWardenEvent(wardenEventEndShift)
            .then((value) async {
          await auth.logout().then((value) {
            Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName, (Route<dynamic> route) => false);
            CherryToast.success(
              displayCloseButton: false,
              title: Text(
                'End of shift',
                style: CustomTextStyle.h5.copyWith(color: ColorTheme.success),
              ),
              toastPosition: Position.bottom,
              borderRadius: 5,
            ).show(context);
          });
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

    List<Widget> getList() {
      return DataMenuItem()
          .data
          .map(
            (e) => ItemMenuWidget(
              itemMenu: e,
              onTap: e.route == 'comming soon'
                  ? () {
                      Navigator.of(context).pop();
                      CherryToast.info(
                        displayCloseButton: false,
                        title: Text(
                          'Comming soon',
                          style: CustomTextStyle.h5
                              .copyWith(color: ColorTheme.primary),
                        ),
                        toastPosition: Position.bottom,
                        borderRadius: 5,
                      ).show(context);
                    }
                  : e.route == 'testPrinter'
                      ? () async {
                          if (bluetoothPrinterHelper.selectedPrinter == null) {
                            CherryToast.error(
                              toastDuration: const Duration(seconds: 2),
                              title: Text(
                                'Please connect to the printer via bluetooth and try again',
                                style: CustomTextStyle.h5
                                    .copyWith(color: ColorTheme.danger),
                              ),
                              toastPosition: Position.bottom,
                              borderRadius: 5,
                            ).show(context);
                          } else {
                            showLoading();
                            bluetoothPrinterHelper.printReceiveTest();
                          }
                        }
                      : () => Navigator.of(context).pushReplacementNamed(
                            e.route!,
                          ),
            ),
          )
          .toList();
    }

    List<NavItemMenu> navItem = [
      NavItemMenu(
        title: 'Emerg. call',
        icon: SvgPicture.asset(
          'assets/svg/IconCall2.svg',
        ),
        route: HomeOverview.routeName,
        background: ColorTheme.grey200,
        check: null,
        setCheck: () async {
          final call = Uri.parse('tel:0981832226');
          if (await canLaunchUrl(call)) {
            launchUrl(call);
          } else {
            throw 'Could not launch $call';
          }
        },
      ),
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SizedBox(
        width: widthScreen > 450 ? widthScreen * 0.45 : widthScreen * 0.85,
        child: Drawer(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    InfoDrawer(
                      isDrawer: true,
                      assetImage: wardensProvider.wardens?.Picture ??
                          "assets/images/userAvatar.png",
                      name: "Hello ${wardensProvider.wardens?.FullName ?? ""}",
                      location: locations.location?.Name ?? 'Empty name!!',
                      zone: locations.zone?.Name ?? 'Empty name!!',
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
                      padding: EdgeInsets.all(8.0),
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
                    SizedBox(height: heightScreen / 3.5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 30,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: getListNav(),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

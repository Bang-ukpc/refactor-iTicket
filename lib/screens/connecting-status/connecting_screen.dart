import 'dart:async';
import 'dart:developer' as developer;
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iWarden/common/circle.dart';
import 'package:iWarden/common/dot.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart' as toast;
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/abort_controller.dart';
import 'package:iWarden/controllers/contravention_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/connecting-status/background_service_config.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:provider/provider.dart';

import '../../providers/locations.dart';
import '../login_screens.dart';

enum StateDevice { connected, pending, disconnect }

class ConnectingScreen extends StatefulWidget {
  static const routeName = '/connect';
  const ConnectingScreen({super.key});

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  bool isPending = true;
  bool pendingGetCurrentLocation = true;
  bool checkGps = false;
  Position? currentLocationOfWarder;
  late StreamSubscription<ServiceStatus> serviceStatusStreamSubscription;
  bool? checkBluetooth;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  ServiceStatus gpsConnectionStatus = ServiceStatus.disabled;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  List<CancellationReason> cancellationReasonList = [];

  _buildConnect(String title, StateDevice state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 19),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: CustomTextStyle.h5,
          ),
          if (state == StateDevice.pending)
            SpinKitCircle(
              color: ColorTheme.primary,
              size: 18,
            ),
          if (state == StateDevice.disconnect)
            SvgPicture.asset("assets/svg/IconDotCom.svg"),
          if (state == StateDevice.connected)
            SvgPicture.asset("assets/svg/IconCompleteActive.svg")
        ],
      ),
    );
  }

  // Check bluetooth connection
  void _checkDeviceBluetoothIsOn() async {
    var check = await FlutterBluePlus.instance.isOn;
    setState(() {
      checkBluetooth = check;
    });
  }

  // Check GPS connection
  Future<void> checkGpsConnectingStatus() async {
    if (!mounted) {
      return Future.value(null);
    }
    await Geolocator.isLocationServiceEnabled().then((status) {
      setState(() {
        if (status == true) {
          gpsConnectionStatus = ServiceStatus.enabled;
        } else {
          gpsConnectionStatus = ServiceStatus.disabled;
        }
      });
    });
  }

  Future<void> _updateConnectionGpsStatus(ServiceStatus result) async {
    if (!mounted) {
      return Future.value(null);
    }
    setState(() {
      gpsConnectionStatus = result;
    });
  }

  // Check network connection
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  // Get current location
  void getCurrentLocationOfWarden() async {
    await currentLocationPosition.getCurrentLocation().then((value) {
      setState(() {
        pendingGetCurrentLocation = false;
        currentLocationOfWarder = value;
      });
      checkPermissionGPS();
    }).catchError((err) {
      setState(() {
        pendingGetCurrentLocation = false;
      });
    });
  }

  void checkPermissionGPS() async {
    var check = await permission.Permission.locationWhenInUse.isGranted;
    setState(() {
      checkGps = check;
    });
  }

  void onStartBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      await initializeService();
    }
  }

  void getContraventionReasonList() async {
    final Pagination list =
        await contraventionController.getContraventionReasonServiceList();
    setState(() {
      contraventionReasonList = list.rows
          .map((item) => ContraventionReasonTranslations.fromJson(item))
          .toList();
    });
  }

  void getCancellationReasonList() async {
    await abortController.getCancellationReasonList().then((value) {
      setState(() {
        cancellationReasonList = value;
      });
    }).catchError((err) {
      print(err);
      throw Error();
    });
  }

  @override
  void initState() {
    super.initState();
    onStartBackgroundService();
    getCurrentLocationOfWarden();
    getContraventionReasonList();
    getCancellationReasonList();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final wardensInfo = Provider.of<WardensInfo>(context, listen: false);
      await wardensInfo.getWardensInfoLogging().then((value) {
        setState(() {
          isPending = false;
        });
      }).catchError((err) {
        setState(() {
          isPending = false;
        });
      });
    });
    checkGpsConnectingStatus();
    serviceStatusStreamSubscription =
        Geolocator.getServiceStatusStream().listen(_updateConnectionGpsStatus);
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkDeviceBluetoothIsOn();
  }

  StateDevice checkState(bool check) {
    if (check) {
      return StateDevice.connected;
    } else {
      return StateDevice.disconnect;
    }
  }

  @override
  void dispose() {
    serviceStatusStreamSubscription.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wardensProvider = Provider.of<WardensInfo>(context);
    final locations = Provider.of<Locations>(context);
    //check is route from checkout screen
    final data = ModalRoute.of(context)!.settings.arguments as dynamic;
    final isCheckoutScreen = (data == null) ? false : true;

    final wardenEventStartShift = WardenEvent(
      type: TypeWardenEvent.StartShift.index,
      detail: 'Warden has started shift',
      latitude: currentLocationOfWarder?.latitude ?? 0,
      longitude: currentLocationOfWarder?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
    );

    void onStartShift() async {
      try {
        showCircularProgressIndicator(context: context, text: 'Starting shift');
        await userController
            .createWardenEvent(wardenEventStartShift)
            .then((value) async {
          final service = FlutterBackgroundService();
          var isRunning = await service.isRunning();
          if (!isRunning) {
            await initializeService();
          }
          if (!mounted) return;
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(LocationScreen.routeName);
        });
      } on DioError catch (error) {
        if (!mounted) return;
        if (error.type == DioErrorType.other) {
          Navigator.of(context).pop();
          toast.CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              error.message.length > Constant.errorTypeOther
                  ? 'Something went wrong, please try again'
                  : error.message,
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: toast.Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        Navigator.of(context).pop();
        toast.CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: toast.Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

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

    void onLogout(Auth auth) async {
      try {
        showCircularProgressIndicator(context: context, text: "Logging out");
        await userController
            .createWardenEvent(wardenEventEndShift)
            .then((value) async {
          await auth.logout().then((value) {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName, (Route<dynamic> route) => false);
            toast.CherryToast.success(
              displayCloseButton: false,
              title: Text(
                'Log out successfully',
                style: CustomTextStyle.h4.copyWith(color: ColorTheme.success),
              ),
              toastPosition: toast.Position.bottom,
              borderRadius: 5,
            ).show(context);
          });
        });
      } on DioError catch (error) {
        if (error.type == DioErrorType.other) {
          Navigator.of(context).pop();
          toast.CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              error.message.length > Constant.errorTypeOther
                  ? 'Something went wrong, please try again'
                  : error.message,
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: toast.Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        Navigator.of(context).pop();
        toast.CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: toast.Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 80,
              ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (pendingGetCurrentLocation == true)
                      Text(
                        "Connecting pair devices",
                        style: CustomTextStyle.h3
                            .copyWith(color: ColorTheme.primary),
                      ),
                    if (isPending == false &&
                        pendingGetCurrentLocation == false)
                      Text(
                        isCheckoutScreen
                            ? 'Shift ended successfully'
                            : "Connected successfully",
                        style: CustomTextStyle.h3
                            .copyWith(color: ColorTheme.primary),
                      ),
                    if (pendingGetCurrentLocation == true)
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 2),
                        child: SpinKitThreeBounce(
                          color: ColorTheme.primary,
                          size: 7,
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    isPending == false
                        ? pendingGetCurrentLocation == false
                            ? _buildConnect("1. Connect bluetooth",
                                checkState(checkBluetooth == true))
                            : _buildConnect(
                                '1. Connect bluetooth', StateDevice.pending)
                        : _buildConnect(
                            '1. Connect bluetooth', StateDevice.pending),
                    isPending == false
                        ? pendingGetCurrentLocation == false
                            ? _buildConnect(
                                "2. Connect network",
                                checkState(
                                  _connectionStatus ==
                                          ConnectivityResult.mobile ||
                                      _connectionStatus ==
                                          ConnectivityResult.wifi,
                                ),
                              )
                            : _buildConnect(
                                '2. Connect network', StateDevice.pending)
                        : _buildConnect(
                            '2. Connect network', StateDevice.pending),
                    isPending == false
                        ? pendingGetCurrentLocation == false
                            ? _buildConnect(
                                "3. GPS has been turned on",
                                checkState(gpsConnectionStatus ==
                                    ServiceStatus.enabled))
                            : _buildConnect('3. GPS has been turned on',
                                StateDevice.pending)
                        : _buildConnect(
                            '3. GPS has been turned on', StateDevice.pending),
                  ],
                ),
              ),
              if (isPending == false && pendingGetCurrentLocation == false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (isCheckoutScreen)
                        Consumer<Auth>(
                          builder: (context, auth, _) {
                            return Expanded(
                              child: ElevatedButton.icon(
                                icon: SvgPicture.asset(
                                  "assets/svg/IconEndShift.svg",
                                  width: 18,
                                  height: 18,
                                  color: ColorTheme.textPrimary,
                                ),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  backgroundColor: ColorTheme.grey300,
                                ),
                                onPressed: () {
                                  onLogout(auth);
                                },
                                label: Text(
                                  "Log out",
                                  style: CustomTextStyle.h5.copyWith(
                                    color: ColorTheme.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      if (isCheckoutScreen)
                        const SizedBox(
                          width: 16,
                        ),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon:
                              SvgPicture.asset("assets/svg/IconStartShift.svg"),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () {
                            if (checkGps == true) {
                              onStartShift();
                            } else {
                              toast.CherryToast.error(
                                toastDuration: const Duration(seconds: 5),
                                title: Text(
                                  'Please allow the app to access your location to continue',
                                  style: CustomTextStyle.h4.copyWith(
                                    color: ColorTheme.danger,
                                  ),
                                ),
                                toastPosition: toast.Position.bottom,
                                borderRadius: 5,
                              ).show(context);
                            }
                          },
                          label: Text(
                            "Start shift",
                            style: CustomTextStyle.h5
                                .copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

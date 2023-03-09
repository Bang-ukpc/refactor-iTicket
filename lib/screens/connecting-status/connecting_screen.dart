import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_kronos/flutter_kronos.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iWarden/common/circle.dart';
import 'package:iWarden/common/dot.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/common/toast.dart' as toast;
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/connecting-status/background_service_config.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/services/cache/factory/cache_factory.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:provider/provider.dart';

import '../../helpers/my_navigator_observer.dart';
import '../login_screens.dart';

enum StateDevice { connected, pending, disconnect }

class ConnectingScreen extends StatefulWidget {
  static const routeName = '/connect';
  const ConnectingScreen({super.key});

  @override
  BaseStatefulState<ConnectingScreen> createState() => _ConnectingScreenState();
}

String defaultErrorMessage =
    "Can't sync the data. Please check your network and try to refresh the app again.";

class _ConnectingScreenState extends BaseStatefulState<ConnectingScreen> {
  bool isPending = true;
  bool pendingGetCurrentLocation = true;
  late StreamSubscription<ServiceStatus> serviceStatusStreamSubscription;
  bool? checkBluetooth;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  ServiceStatus gpsConnectionStatus = ServiceStatus.disabled;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  List<ContraventionReasonTranslations> contraventionReasonList = [];
  bool isSyncedRota = false;
  String errorMessage = defaultErrorMessage;
  bool isCancellationNotNull = false;
  bool isLocationPermission = false;
  bool loadingNTPTime = false;
  bool isNTPTimeNull = true;
  late CachedServiceFactory cachedServiceFactory;
  Stream<BluetoothState> bluetoothStateStream =
      FlutterBluePlus.instance.state.asBroadcastStream();
  _buildConnect(String title, StateDevice state, {bool required = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: CustomTextStyle.h5,
              ),
              if (required)
                Text(
                  "*",
                  style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
                ),
            ],
          ),
          Row(
            children: [
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
    print('[gpsConnectionStatus] result:  $result');
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
    if (!mounted) return;
    await currentLocationPosition.getCurrentLocation().then((value) {
      setState(() {
        pendingGetCurrentLocation = false;
      });
      checkPermissionGPS();
    }).catchError((err) {
      if (!mounted) return;
      setState(() {
        pendingGetCurrentLocation = false;
      });
    });
  }

  void checkPermissionGPS() async {
    var isGranted = await permission.Permission.locationWhenInUse.isGranted;
    setState(() {
      isLocationPermission = isGranted;
    });
  }

  void onStartBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      await initializeService();
    }
  }

  Future<void> syncRotaList() async {
    try {
      await cachedServiceFactory.rotaWithLocationCachedService.syncFromServer();
      var rotas =
          await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      setState(() {
        isSyncedRota = rotas.isNotEmpty;
        errorMessage = rotas.isEmpty
            ? "Check with systems admin, that rota shift has been allocated."
            : errorMessage;
      });
    } catch (e) {
      var rotas =
          await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      setState(() {
        isSyncedRota = rotas.isNotEmpty;
      });
    }
  }

  Future<void> syncCancellationReasonList() async {
    await cachedServiceFactory.cancellationReasonCachedService.syncFromServer();
    await getCancellationReasons();
  }

  Future<void> syncContraventionReasonList() async {
    await cachedServiceFactory.defaultContraventionReasonCachedService
        .syncFromServer();
    await cachedServiceFactory.rotaWithLocationCachedService
        .syncContraventionReasonForAllZones();
  }

  Future<void> syncAllRequiredData() async {
    setState(() {
      errorMessage = defaultErrorMessage;
    });
    print('GET ROTA');
    await syncRotaList();
    print('GET CANCELLATION REASON');
    await syncCancellationReasonList();
    print('GET CONTRAVENTION REASON');
    await syncContraventionReasonList();
  }

  Future<void> getCancellationReasons() async {
    var cancellationReasons =
        await cachedServiceFactory.cancellationReasonCachedService.getAll();
    print('[Cancellation reason length] ${cancellationReasons.length}');
    setState(() {
      isCancellationNotNull = cancellationReasons.isNotEmpty;
    });
  }

  Logger logger = Logger<ConnectingScreen>();
  Future<void> syncTime() async {
    setState(() {
      loadingNTPTime = true;
    });

    try {
      await timeNTP.sync();
      DateTime? values = await FlutterKronos.getNtpDateTime;
      logger.info(values.toString());
      setState(() {
        isNTPTimeNull = values == null;
        loadingNTPTime = false;
      });
    } catch (e) {
      setState(() {
        loadingNTPTime = false;
        errorMessage =
            "Can't get the server time. Please pull to refresh to get the server time.";
      });
    }
  }

  bool isDataValid() {
    if (!isSyncedRota || !isCancellationNotNull || isNTPTimeNull) {
      return false;
    } else {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    onStartBackgroundService();
    getCurrentLocationOfWarden();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final wardensInfo = Provider.of<WardensInfo>(context, listen: false);
      await wardensInfo.getWardensInfoLogging().then((value) async {
        return;
      }).catchError((err) {
        return;
      });
      cachedServiceFactory = CachedServiceFactory(wardensInfo.wardens?.Id ?? 0);
      await syncAllRequiredData();
      await syncTime();
      setState(() {
        isPending = false;
      });
    });
    checkGpsConnectingStatus();
    serviceStatusStreamSubscription =
        Geolocator.getServiceStatusStream().listen(_updateConnectionGpsStatus);

    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    bluetoothStateStream.listen((bluetoothState) {
      _checkDeviceBluetoothIsOn();
    });
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

  Future<void> refreshPermissionGPS() async {
    var check = await permission.Permission.locationWhenInUse.isGranted;
    setState(() {
      isLocationPermission = check;
      isPending = true;
    });
    await syncTime();
    await syncAllRequiredData();

    setState(() {
      isPending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wardensProvider = Provider.of<WardensInfo>(context);
    //check is route from checkout screen
    logger.info(isNTPTimeNull);
    final data = ModalRoute.of(context)!.settings.arguments as dynamic;
    final isCheckoutScreen = (data == null) ? false : true;

    final wardenEventStartShift = WardenEvent(
      type: TypeWardenEvent.StartShift.index,
      detail: 'Warden has started shift',
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardensProvider.wardens?.Id ?? 0,
    );

    void onStartShift() async {
      try {
        showCircularProgressIndicator(context: context, text: 'Starting shift');
        await createdWardenEventLocalService
            .create(wardenEventStartShift)
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

    void onLogout(Auth auth) async {
      try {
        showCircularProgressIndicator(context: context, text: "Logging out");
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
          child: RefreshIndicator(
            onRefresh: refreshPermissionGPS,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 60,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPending == true ||
                            pendingGetCurrentLocation == true)
                          Row(
                            children: [
                              Text(
                                "Connecting paired devices",
                                style: CustomTextStyle.h3
                                    .copyWith(color: ColorTheme.primary),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 10, left: 2),
                                child: SpinKitThreeBounce(
                                  color: ColorTheme.primary,
                                  size: 7,
                                ),
                              )
                            ],
                          ),
                        if (isPending == false &&
                            pendingGetCurrentLocation == false)
                          Text(
                            "Configuration status",
                            style: CustomTextStyle.h3
                                .copyWith(color: ColorTheme.primary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Connectivity status",
                          style: CustomTextStyle.h5.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        isPending == false
                            ? pendingGetCurrentLocation == false
                                ? _buildConnect(
                                    "1. Network (Mobile or WiFi)",
                                    checkState(
                                      _connectionStatus ==
                                              ConnectivityResult.mobile ||
                                          _connectionStatus ==
                                              ConnectivityResult.wifi,
                                    ),
                                  )
                                : _buildConnect('1. Network (Mobile or WiFi)',
                                    StateDevice.pending)
                            : _buildConnect('1. Network (Mobile or WiFi)',
                                StateDevice.pending),
                        isPending == false
                            ? pendingGetCurrentLocation == false
                                ? _buildConnect(
                                    required: true,
                                    "2. GPS",
                                    checkState(gpsConnectionStatus ==
                                            ServiceStatus.enabled &&
                                        isLocationPermission))
                                : _buildConnect(
                                    required: true,
                                    '2. GPS',
                                    StateDevice.pending)
                            : _buildConnect(
                                required: true, '2. GPS', StateDevice.pending),
                        isPending == false
                            ? pendingGetCurrentLocation == false
                                ? _buildConnect("3. Bluetooth",
                                    checkState(checkBluetooth == true))
                                : _buildConnect(
                                    '3. Bluetooth', StateDevice.pending)
                            : _buildConnect(
                                '3. Bluetooth', StateDevice.pending),

                        // isPending == false
                        //     ? pendingGetCurrentLocation == false
                        //         ? _buildConnect(
                        //             required: true,
                        //             "4. Location permission",
                        //             checkState(isLocationPermission),
                        //           )
                        //         : _buildConnect(
                        //             required: true,
                        //             '4. Location permission',
                        //             StateDevice.pending)
                        //     : _buildConnect(
                        //         required: true,
                        //         '4. Location permission',
                        //         StateDevice.pending),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "Data download",
                          style: CustomTextStyle.h5.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ColorTheme.textPrimary),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        isPending == false
                            ? pendingGetCurrentLocation == false
                                ? _buildConnect(
                                    required: true,
                                    "1. Rota shifts and locations",
                                    checkState(
                                      isSyncedRota,
                                    ),
                                  )
                                : _buildConnect(
                                    required: true,
                                    '1. Rota shifts and locations',
                                    StateDevice.pending)
                            : _buildConnect(
                                required: true,
                                '1. Rota shifts and locations',
                                StateDevice.pending),
                        isPending == false
                            ? pendingGetCurrentLocation == false
                                ? _buildConnect(
                                    required: true,
                                    "2. Cancellation reasons",
                                    checkState(isCancellationNotNull),
                                  )
                                : _buildConnect(
                                    required: true,
                                    '2. Cancellation reasons',
                                    StateDevice.pending)
                            : _buildConnect(
                                required: true,
                                '2. Cancellation reasons',
                                StateDevice.pending),
                        isPending == false
                            ? loadingNTPTime == false
                                ? _buildConnect(
                                    required: true,
                                    "3. Server time",
                                    checkState(!isNTPTimeNull),
                                  )
                                : _buildConnect(
                                    required: true,
                                    '3. Server time',
                                    StateDevice.pending)
                            : _buildConnect(
                                required: true,
                                '3. Server time',
                                StateDevice.pending),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '*',
                          style: TextStyle(color: ColorTheme.danger),
                        ),
                        const Expanded(
                          child: Text(
                            'Mandatory service and data required to operate iTicket.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 32,
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
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
                              icon: SvgPicture.asset(
                                  "assets/svg/IconStartShift.svg"),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () async {
                                if (isLocationPermission == true) {
                                  getCurrentLocationOfWarden();
                                  if (gpsConnectionStatus ==
                                      ServiceStatus.enabled) {
                                    getCurrentLocationOfWarden();

                                    if (isDataValid()) {
                                      onStartShift();
                                    } else {
                                      toast.CherryToast.error(
                                        toastDuration:
                                            const Duration(seconds: 5),
                                        title: Text(
                                          errorMessage,
                                          style: CustomTextStyle.h4.copyWith(
                                            color: ColorTheme.danger,
                                          ),
                                        ),
                                        toastPosition: toast.Position.bottom,
                                        borderRadius: 5,
                                      ).show(context);
                                    }
                                  } else {
                                    toast.CherryToast.error(
                                      toastDuration: const Duration(seconds: 5),
                                      title: Text(
                                        'Please enable GPS',
                                        style: CustomTextStyle.h4.copyWith(
                                          color: ColorTheme.danger,
                                        ),
                                      ),
                                      toastPosition: toast.Position.bottom,
                                      borderRadius: 5,
                                    ).show(context);
                                  }
                                } else {
                                  permission.Permission.location
                                      .request()
                                      .then((value) async {
                                    if (permission.PermissionStatus.granted ==
                                        value) {
                                      getCurrentLocationOfWarden();

                                      setState(() {
                                        isLocationPermission = true;
                                      });
                                    } else {
                                      toast.CherryToast.error(
                                        toastDuration:
                                            const Duration(seconds: 5),
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
                                  });
                                }
                              },
                              label: Text(
                                "Start shift",
                                style: CustomTextStyle.h5.copyWith(
                                    color: Colors.white, fontSize: 16),
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
        ),
      ),
    );
  }
}

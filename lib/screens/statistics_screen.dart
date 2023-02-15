import 'dart:async';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/controllers/statistic_controller.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/date_filter.dart';
import 'package:iWarden/models/statistic.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:iWarden/widgets/statistic/statistic_item.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StatisticScreen extends StatefulWidget {
  static const routeName = '/statistic';
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  _buildDevice(String nameDevice, bool stateDevice) {
    return Row(
      children: [
        SvgPicture.asset(stateDevice
            ? "assets/svg/IconCompleteActive.svg"
            : "assets/svg/IconDotCom.svg"),
        const SizedBox(
          width: 4,
        ),
        Text(
          nameDevice,
          style: CustomTextStyle.body2,
        )
      ],
    );
  }

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final bool connected = true;
  bool checkGps = false;
  bool checkBluetooth = false;
  bool checkCamera = false;
  late CameraController controller;
  Stream<BluetoothState> bluetoothStateStream =
      FlutterBluePlus.instance.state.asBroadcastStream();
  // check GPS
  void _checkDeviceLocationIsOn() async {
    var check = await Permission.locationWhenInUse.isGranted;
    setState(() {
      checkGps = check;
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

  // Check bluetooth
  void _checkDeviceBluetoothIsOn() async {
    var check = await FlutterBluePlus.instance.isOn;
    setState(() {
      checkBluetooth = check;
    });
  }

  // Check camera
  void checkCameraPermission() async {
    var check = await Permission.camera.isGranted;
    setState(() {
      checkCamera = check;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final locations = Provider.of<Locations>(context, listen: false);
      final warden = Provider.of<WardensInfo>(context, listen: false);

      getDataStatistic(
          locations.zone!.Id as int,
          formatDate.startOfDay(DateTime.now()),
          formatDate.endOfDay(DateTime.now()),
          warden.wardens?.Id ?? 0);
    });
    _checkDeviceLocationIsOn();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkDeviceBluetoothIsOn();
    checkCameraPermission();
    bluetoothStateStream.listen((bluetoothState) {
      _checkDeviceBluetoothIsOn();
    });
    super.initState();
  }

  final dataList = DataDateFilter().data.toList();
  StatisticWardenPropsData? statisticWardenData;
  String? selectedValue = DataDateFilter().data[0].value;

  getDataStatistic(int zoneId, DateTime from, DateTime to, int wardenId) {
    statisticController
        .getDataStatistic(
      StatisticWardenPropsFilter(
        zoneId: zoneId,
        timeEnd: to,
        timeStart: from,
        WardenId: wardenId,
      ),
    )
        .then((value) {
      setState(() {
        statisticWardenData = value;
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warden = Provider.of<WardensInfo>(context, listen: false);

    Widget listDevice = Container(
      height: 64,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDevice("GPS", checkGps),
                const SizedBox(
                  height: 8,
                ),
                _buildDevice("Bluetooth", checkBluetooth),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDevice("Network status",
                    _connectionStatus != ConnectivityResult.none),
                const SizedBox(
                  height: 8,
                ),
                _buildDevice("Camera", checkCamera),
              ],
            ),
          ),
        ],
      ),
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: "Statistics",
          automaticallyImplyLeading: true,
          onRedirect: () =>
              Navigator.of(context).popAndPushNamed(HomeOverview.routeName),
        ),
        drawer: const MyDrawer(),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 8,
              ),
              listDevice,
              const SizedBox(
                height: 8,
              ),
              if (statisticWardenData != null)
                Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.width < 450
                      ? MediaQuery.of(context).size.height -
                          (58 + 8 + 16 + 55 + 24)
                      : null,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text(
                                "My statistic",
                                style: CustomTextStyle.h5
                                    .copyWith(fontWeight: FontWeight.w600),
                              )),
                          Expanded(
                            flex: 1,
                            child: DropdownSearch<DateFilter>(
                              dropdownBuilder: (context, selectedItem) {
                                return Text(
                                    selectedItem == null
                                        ? "Date filter"
                                        : selectedItem.label,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: selectedItem == null
                                            ? ColorTheme.grey400
                                            : ColorTheme.textPrimary));
                              },
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: dropDownButtonStyle
                                    .getInputDecorationCustom(
                                  hintText: 'Date filter',
                                ),
                              ),
                              items: dataList,
                              selectedItem: dataList[0],
                              itemAsString: (item) => item.label,
                              popupProps: PopupProps.menu(
                                fit: FlexFit.loose,
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                itemBuilder: (context, item, isSelected) =>
                                    DropDownItem(
                                  isSelected: item.value == selectedValue,
                                  title: item.label,
                                ),
                              ),
                              onChanged: (value) {
                                String testa = value!.value;
                                String from = testa.split(',')[0];
                                String to = testa.split(',')[1];
                                getDataStatistic(
                                    Provider.of<Locations>(context,
                                            listen: false)
                                        .zone!
                                        .Id as int,
                                    DateTime.parse(
                                        from.substring(7, from.length)),
                                    DateTime.parse(
                                        to.substring(5, to.length - 1)),
                                    warden.wardens?.Id ?? 0);
                                setState(() {
                                  selectedValue = value.value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: StatisticItem(
                              assetIcon: "assets/svg/IconFirstSeen.svg",
                              background: ColorTheme.lighterPrimary,
                              quantity: statisticWardenData!.firstSeen,
                              title: "First seen",
                            ),
                          ),
                          const SizedBox(
                            width: 32,
                          ),
                          Expanded(
                            child: StatisticItem(
                              assetIcon: "assets/svg/IconGrace.svg",
                              background: ColorTheme.lightDanger,
                              quantity: statisticWardenData!.gracePeriod,
                              title: "Grace period",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: StatisticItem(
                              assetIcon:
                                  "assets/svg/IconParkingChargesHome.svg",
                              background: ColorTheme.lighterSecondary,
                              quantity: statisticWardenData!.issuedPCN,
                              title: "Issued PCN",
                            ),
                          ),
                          const SizedBox(
                            width: 32,
                          ),
                          Expanded(
                            child: StatisticItem(
                              assetIcon: "assets/svg/IconWarning.svg",
                              background: ColorTheme.grey200,
                              quantity: statisticWardenData!.abortedPCN,
                              title: "Aborted PCN",
                            ),
                          ),
                        ],
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

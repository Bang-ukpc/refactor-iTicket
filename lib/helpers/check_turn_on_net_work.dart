import 'package:connectivity_plus/connectivity_plus.dart';

class CheckTurnOnNetWork {
  Future<bool> turnOnWifiAndMobile() async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    return connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile;
  }
}

final checkTurnOnNetWork = CheckTurnOnNetWork();

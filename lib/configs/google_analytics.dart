import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class EventAnalytics {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> clickButton({user = String, button = String}) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());

    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      await analytics.logEvent(
        name: "click_button",
        parameters: {
          "button": button,
          "user": user,
        },
      );
    } else {
      return;
    }
  }
}

// final eventAnalytics = EventAnalytics();

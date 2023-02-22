import 'package:firebase_analytics/firebase_analytics.dart';

class EventAnalytics {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> clickButton({user = String, button = String}) async {
    await analytics.logEvent(
      name: "click_button",
      parameters: {
        "button": button,
        "user": user,
      },
    );
    return;
  }
}

// final eventAnalytics = EventAnalytics();

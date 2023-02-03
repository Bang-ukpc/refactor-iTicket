import 'package:firebase_analytics/firebase_analytics.dart';

class EventAnalytics {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Future<void> setEvent() async {
    await analytics.logEvent(
      name: "click_button",
      parameters: {
        "button": "Start shift",
        "test": "test",
      },
    );
  }

  void test() async {
    print("testtttttttttttt");
    await analytics.logBeginCheckout(
      value: 10.0,
      currency: 'USD',
      items: [
        AnalyticsEventItem(itemName: 'Socks', itemId: 'xjw73ndnw', price: 10),
      ],
      coupon: '10PERCENTOFF',
    );
    print('logEvent succeeded');
  }
}

final eventAnalytics = EventAnalytics();

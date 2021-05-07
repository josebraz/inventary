

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'extensions/Utils.dart';

class StatisticsManager {

  static final StatisticsManager _singleton = StatisticsManager._internal();

  late final FirebaseAnalytics analytics;
  late final FirebaseAnalyticsObserver observer;

  factory StatisticsManager() {
    return _singleton;
  }

  StatisticsManager._internal() {
    analytics = FirebaseAnalytics();
    observer = FirebaseAnalyticsObserver(analytics: analytics);

    setProperties();
  }

  void setProperties() async {
    analytics.setUserProperty(name: "device_id", value: await Utils.getDeviceId());
    final email = await Utils.getUserEmail();
    if (email != null) {
      analytics.setUserProperty(name: "email", value: email);
    }
  }


}
import 'package:flutter/material.dart';
import 'package:iWarden/providers/time_ntp.dart';

abstract class BaseStatefulState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    DateTime? dateTime = await timeNTP.getTimeNTP();
    switch (state) {
      case AppLifecycleState.resumed:
        if (dateTime == null) {
          timeNTP.showDialogTime();
        }
        break;
      case AppLifecycleState.paused:
        break;
      default:
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:provider/provider.dart';

abstract class BaseStatefulState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
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
    final syncData = Provider.of<SyncData>(context, listen: false);
    DateTime? dateTime = await timeNTP.getTimeNTP();
    switch (state) {
      case AppLifecycleState.resumed:
        if (dateTime == null) {
          timeNTP.showDialogTime();
        }
        print("[AppLifecycleState] resumed");
        break;
      case AppLifecycleState.paused:
        print("[AppLifecycleState] paused");
        syncData.stopSync();
        break;
      default:
        break;
    }
  }
}

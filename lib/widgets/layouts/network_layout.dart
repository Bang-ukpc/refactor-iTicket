import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/services/local/sync_factory.dart';
import 'package:provider/provider.dart';

import '../../providers/auth.dart';

class NetworkLayout extends StatefulWidget {
  final Widget myWidget;
  const NetworkLayout({required this.myWidget, super.key});

  @override
  State<NetworkLayout> createState() => _NetworkLayoutState();
}

class _NetworkLayoutState extends State<NetworkLayout> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final authProvider = Provider.of<Auth>(context, listen: false);
      bool checkIsAuth = await authProvider.isAuth();
      if (checkIsAuth == true) {
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          // syncFactory.syncToServer();
          await currentLocationPosition.getCurrentLocation();
        });
      } else {
        if (_timer != null) {
          _timer!.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.myWidget,
    );
  }
}

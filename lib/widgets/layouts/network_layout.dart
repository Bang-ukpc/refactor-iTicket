import 'package:flutter/material.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';

class NetworkLayout extends StatefulWidget {
  final Widget myWidget;
  const NetworkLayout({required this.myWidget, super.key});

  @override
  State<NetworkLayout> createState() => _NetworkLayoutState();
}

class _NetworkLayoutState extends State<NetworkLayout> {
  Future setSyncDataFuncStatus() async {
    await SharedPreferencesHelper.setBoolValue('isSyncFuncActive', false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await setSyncDataFuncStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.myWidget,
    );
  }
}

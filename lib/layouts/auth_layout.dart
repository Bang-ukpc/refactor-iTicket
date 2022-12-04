import 'package:flutter/material.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  const AuthLayout({required this.child, super.key});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  void _askPermission() {
    Permission.locationAlways.request();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final wardensInfo = Provider.of<WardensInfo>(context, listen: false);
      final authProvider = Provider.of<Auth>(context, listen: false);
      try {
        await wardensInfo.getWardersInfoLogging();
      } catch (error) {
        await authProvider.logout().then((value) {
          Navigator.of(context).pushNamed(LoginScreen.routeName);
        });
      }
    });
    _askPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:provider/provider.dart';

class AuthLayout extends StatefulWidget {
  final Widget child;
  const AuthLayout({required this.child, super.key});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
    );
  }
}

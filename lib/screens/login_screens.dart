import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/dot.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../theme/color.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<Auth>(context);

    void showLoading() {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: ColorTheme.mask,
        builder: (_) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Signing in',
                        style: CustomTextStyle.h3.copyWith(
                          decoration: TextDecoration.none,
                          color: ColorTheme.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10, left: 2),
                        child: const SpinKitThreeBounce(
                          color: ColorTheme.white,
                          size: 7,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height < 400 ? 0 : 80,
              ),
              child: Column(
                mainAxisAlignment: MediaQuery.of(context).size.height < 400
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 107,
                      height: 40,
                      child: Image.asset("assets/images/LogoUKPC.png")),
                  const SizedBox(
                    height: 60,
                  ),
                  Text(
                    "Parking operative",
                    style: CustomTextStyle.h6.copyWith(
                      color: ColorTheme.grey600,
                    ),
                  ),
                  Text(
                    "iTicket",
                    style:
                        CustomTextStyle.h1.copyWith(color: ColorTheme.primary),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  const Text(
                    "Welcome to iWarden! We’re glad you’re here!",
                    style: CustomTextStyle.h6,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      authProvider.loginWithMicrosoft(context, showLoading);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(width: 1.0, color: ColorTheme.primary),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 35,
                      ),
                    ),
                    icon: SvgPicture.asset("assets/svg/IconMicrosoft.svg"),
                    label: const Text(
                      "Sign in with Microsoft",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

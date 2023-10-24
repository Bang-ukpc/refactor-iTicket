import 'package:flutter/material.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class LoginLayout extends StatelessWidget {
  final Widget? title;
  final Widget desc;
  final Widget child;
  const LoginLayout({
    this.title,
    required this.desc,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const VersionName(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height < 400 ? 16 : 80,
                  left: 32,
                  right: 32,
                  bottom: MediaQuery.of(context).size.height < 400 ? 16 : 0,
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
                      height: 32,
                    ),
                    title ??
                        Column(
                          children: [
                            Text(
                              "Parking Operatives",
                              style: CustomTextStyle.h5.copyWith(
                                color: ColorTheme.grey600,
                              ),
                            ),
                            Text(
                              "iTicket",
                              style: CustomTextStyle.h1.copyWith(
                                color: ColorTheme.primary,
                              ),
                            ),
                          ],
                        ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: desc,
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

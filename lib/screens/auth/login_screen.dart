import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/helpers/auth.dart';
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/screens/auth/enter_email_screen.dart';
import 'package:iWarden/screens/auth/enter_otp_screen.dart';
import 'package:iWarden/screens/auth/layouts/login_layout.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

enum LoginProcess {
  loginOption,
  enterEmail,
  otp,
}

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var loginOption = LoginProcess.loginOption;
  String emailToSendOtp = "";

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final syncData = Provider.of<SyncData>(context, listen: false);
      syncData.stopSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget buildLoginScreen(LoginProcess loginProcess) {
      switch (loginProcess) {
        case LoginProcess.enterEmail:
          return EnterEmailToLogin(
            onContinue: (email) {
              setState(() {
                emailToSendOtp = email;
                loginOption = LoginProcess.otp;
              });
            },
            onBack: () {
              setState(() {
                loginOption = LoginProcess.loginOption;
              });
            },
          );
        case LoginProcess.otp:
          return EnterOTPScreen(
            emailToSendOtp: emailToSendOtp,
            onBack: () {
              setState(() {
                loginOption = LoginProcess.enterEmail;
              });
            },
          );
        default:
          return LoginLayout(
            desc: const Text(
              "Welcome to iTicket! We’re glad you’re here!",
              style: CustomTextStyle.h5,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      authentication.loginWithMicrosoft(context);
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
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  child: const Row(
                    children: <Widget>[
                      Expanded(
                        child: Divider(
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("or"),
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: () {
                    setState(() {
                      loginOption = LoginProcess.enterEmail;
                    });
                  },
                  child: const Text('Sign in with email'),
                ),
              ],
            ),
          );
      }
    }

    return buildLoginScreen(loginOption);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/alert_helper.dart';
import 'package:iWarden/screens/auth/layouts/login_layout.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

class EnterEmailToLogin extends StatefulWidget {
  final Function(String email) onContinue;
  final void Function()? onBack;

  const EnterEmailToLogin({
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  @override
  State<EnterEmailToLogin> createState() => _EnterEmailToLoginState();
}

class _EnterEmailToLoginState extends State<EnterEmailToLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  void onContinue() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    showCircularProgressIndicator(context: context);
    try {
      await userController.sendOtpLogin(_emailController.text).then((value) {
        Navigator.of(context).pop();
        widget.onContinue(_emailController.text);
      });
    } on DioError catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      alertHelper.errorResponseApi(e);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: LoginLayout(
        desc: const Column(
          children: [
            Text('Welcome to iTicket'),
            Text("Please enter your e-mail below:"),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  style: CustomTextStyle.h5.copyWith(fontSize: 16),
                  decoration: const InputDecoration(
                    label: Text("Email"),
                    hintText: "Enter your email address",
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: ColorTheme.grey400,
                    ),
                    errorStyle: TextStyle(
                      height: 0,
                    ),
                    fillColor: Colors.white,
                  ),
                  validator: ((value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email address';
                    } else {
                      if (!value.isValidEmail()) {
                        return "Email is invalid. Please try again!";
                      }
                      return null;
                    }
                  }),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: ColorTheme.grey300,
                    ),
                    onPressed: widget.onBack,
                    child: Text(
                      "Back",
                      style: CustomTextStyle.h5.copyWith(
                        color: ColorTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 24,
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

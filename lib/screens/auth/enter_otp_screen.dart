import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/helpers/alert_helper.dart';
import 'package:iWarden/helpers/auth.dart';
import 'package:iWarden/screens/auth/layouts/login_layout.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class EnterOTPScreen extends StatefulWidget {
  final String emailToSendOtp;
  final void Function()? onBack;
  const EnterOTPScreen({
    required this.emailToSendOtp,
    required this.onBack,
    super.key,
  });

  @override
  State<EnterOTPScreen> createState() => _EnterOTPScreenState();
}

class _EnterOTPScreenState extends State<EnterOTPScreen> {
  final _otpController = TextEditingController();
  StreamController<ErrorAnimationType>? _errorAnimationController;
  int _countDown = 30;
  late Timer _timer;
  late FocusNode _focusNode;

  void _startCountDown() {
    setState(() {
      _countDown = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countDown--;
        if (_countDown == 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> resendOtp() async {
    showCircularProgressIndicator(context: context);
    try {
      await userController.sendOtpLogin(widget.emailToSendOtp).then((value) {
        Navigator.of(context).pop();
        alertHelper.success("OTP code re-sent successfully.");
        _otpController.clear();
        _focusNode.requestFocus();
      });
    } on DioError catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _otpController.clear();
      alertHelper.error(e);
    }
    _startCountDown();
  }

  void onConfirm() async {
    final isValid = _otpController.text.length == 6;
    if (!isValid) {
      _errorAnimationController?.add(ErrorAnimationType.shake);
      return;
    }

    _focusNode.unfocus();
    showCircularProgressIndicator(context: context);
    try {
      await userController
          .loginWithEmailOtp(
              email: widget.emailToSendOtp, otp: _otpController.text)
          .then((token) async {
        Navigator.of(context).pop();
        await authentication.loginWithEmailOtp(token, context);
      });
    } on DioError catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      _otpController.clear();
      alertHelper.error(e);
    }
  }

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    _errorAnimationController = StreamController<ErrorAnimationType>();
    _startCountDown();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _otpController.dispose();
    _timer.cancel();
    _errorAnimationController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: LoginLayout(
        title: Text(
          'Verification code',
          style: CustomTextStyle.h3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        desc: Column(
          children: [
            const Text('OTP has been sent to email:'),
            Text(
              widget.emailToSendOtp,
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.primary),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 400,
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  errorAnimationController: _errorAnimationController,
                  autoDisposeControllers: false,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: false),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    activeColor: ColorTheme.primary,
                    inactiveColor: Colors.grey[400],
                    inactiveFillColor: ColorTheme.primary,
                  ),
                  focusNode: _focusNode,
                  onCompleted: (value) {
                    onConfirm();
                  },
                ),
              ),
            ),
            const Text("If you didn’t receive a code,"),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: "please click ",
                style: const TextStyle(color: ColorTheme.textPrimary),
                children: [
                  TextSpan(
                    text:
                        "Resend ${_countDown > 0 ? 'in $_countDown sec' : ''}",
                    recognizer: TapGestureRecognizer()
                      ..onTap = _countDown > 0 ? null : resendOtp,
                    style: CustomTextStyle.h5.copyWith(
                      color: ColorTheme.danger,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 24,
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
                    onPressed: () {
                      onConfirm();
                    },
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

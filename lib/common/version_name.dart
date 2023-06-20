import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionName extends StatefulWidget {
  const VersionName({super.key});

  @override
  State<VersionName> createState() => _VersionNameState();
}

class _VersionNameState extends State<VersionName> {
  String verisonName = '';
  setVerisonName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      verisonName = packageInfo.version;
    });
  }

  @override
  void initState() {
    setVerisonName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "iTicket $verisonName",
      style: CustomTextStyle.body1.copyWith(color: ColorTheme.grey600),
      textAlign: TextAlign.center,
    );
  }
}

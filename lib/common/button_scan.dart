import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/theme/color.dart';

class ButtonScan extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const ButtonScan({super.key, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: ColorTheme.primary,
      child: Container(
        width: 65,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.all(12.5),
        child: SvgPicture.asset(
          "assets/svg/IconSearch.svg",
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class TagOnOff extends StatelessWidget {
  final bool offline;

  const TagOnOff({super.key, required this.offline});

  @override
  Widget build(BuildContext context) {
    Color color = !offline ? ColorTheme.primary : ColorTheme.secondary;
    Widget dot() {
      return Container(
        height: 8,
        width: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color:
            !offline ? ColorTheme.lighterPrimary : ColorTheme.lighterSecondary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          dot(),
          const SizedBox(
            width: 5,
          ),
          Text(
            !offline ? "Synced" : "Syncing",
            style: CustomTextStyle.body1.copyWith(
              color: color,
            ),
          )
        ],
      ),
    );
  }
}

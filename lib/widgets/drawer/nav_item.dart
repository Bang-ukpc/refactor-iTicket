import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/model/nav_item.dart';

class NavItem extends StatelessWidget {
  final NavItemMenu itemMenu;
  const NavItem({super.key, required this.itemMenu});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: itemMenu.setCheck,
      child: Column(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: itemMenu.background,
                borderRadius: BorderRadius.circular(40)),
            child: itemMenu.icon,
          ),
          const SizedBox(height: 4),
          Text(
            itemMenu.title,
            style: CustomTextStyle.h6.copyWith(
              color: itemMenu.check == null
                  ? ColorTheme.grey600
                  : ColorTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

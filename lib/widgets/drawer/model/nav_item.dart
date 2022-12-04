import 'package:flutter/material.dart';

class NavItemMenu {
  final String title;
  final Widget icon;
  final String? route;
  final Color background;
  final bool? check;
  final VoidCallback? setCheck;
  NavItemMenu({
    required this.title,
    required this.icon,
    this.route,
    required this.background,
    this.check,
    this.setCheck,
  });
}

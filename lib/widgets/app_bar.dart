import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool automaticallyImplyLeading;
  final bool? isOpenDrawer;
  final VoidCallback? onRedirect;
  final SystemUiOverlayStyle? systemUiSettings;

  const MyAppBar({
    Key? key,
    required this.title,
    this.automaticallyImplyLeading = false,
    this.onRedirect,
    this.isOpenDrawer = true,
    this.systemUiSettings = const SystemUiOverlayStyle(
      statusBarColor: ColorTheme.textPrimary,
      statusBarIconBrightness: Brightness.light,
    ),
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(54);
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: HomeOverview.routeName == ModalRoute.of(context)!.settings.name
          ? 10
          : 0,
      shadowColor:
          HomeOverview.routeName == ModalRoute.of(context)!.settings.name
              ? ColorTheme.boxShadow3
              : null,
      systemOverlayStyle: systemUiSettings,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: !automaticallyImplyLeading ? 16 : 0,
      title: SizedBox(
        child: Row(
          children: <Widget>[
            if (!automaticallyImplyLeading)
              SvgPicture.asset("assets/svg/LogoHome.svg"),
            if (!automaticallyImplyLeading)
              const SizedBox(
                width: 10,
              ),
            Text(
              title,
              style: CustomTextStyle.h4.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      leading: automaticallyImplyLeading
          ? IconButton(
              icon: SvgPicture.asset("assets/svg/IconBack.svg"),
              onPressed: onRedirect ?? () => Navigator.of(context).pop(),
            )
          : null,
      // leadingWidth: 16,
      actions: [
        isOpenDrawer == true
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}

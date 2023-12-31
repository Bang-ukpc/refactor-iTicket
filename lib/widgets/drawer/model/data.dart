import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/screens/statistics_screen.dart';
import 'package:iWarden/widgets/drawer/model/menu_item.dart';

class DataMenuItem {
  List<ItemMenu> data = [
    ItemMenu('Home', 'assets/svg/LogoHome.svg', HomeOverview.routeName),
    ItemMenu('Forms', 'assets/svg/IconForm.svg', 'coming soon'),
    ItemMenu('Test printer', 'assets/svg/IconPrinter2.svg', 'testPrinter'),
    ItemMenu(
      'Statistic',
      'assets/svg/IconStatistic.svg',
      StatisticScreen.routeName,
    ),
  ];
}

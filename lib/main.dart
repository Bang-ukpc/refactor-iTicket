import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart' as print_issue;
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/routes/routes.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/settings/app_settings.dart';
import 'package:iWarden/theme/theme.dart';
import 'package:iWarden/widgets/layouts/network_layout.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardensInfo()),
        ChangeNotifierProvider(create: (_) => Locations()),
        ChangeNotifierProvider(
          create: (_) => print_issue.PrintIssueProviders(),
        ),
        ChangeNotifierProvider(create: (_) => Auth()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    appSetting.settings();

    return MaterialApp(
      title: 'iTicket',
      theme: themeMain(),
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      home: Scaffold(
        body: NetworkLayout(
          myWidget: Consumer<Auth>(
            builder: (ctx, auth, _) => FutureBuilder<bool>(
              future: auth.isAuth(),
              builder: ((context, snapshot) {
                if (snapshot.data == true) {
                  return const ConnectingScreen();
                } else {
                  return const LoginScreen();
                }
              }),
            ),
          ),
        ),
      ),
      routes: routes,
    );
  }
}

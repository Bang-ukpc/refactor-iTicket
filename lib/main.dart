import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/auth.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart' as print_issue;
import 'package:iWarden/providers/sync_data.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/routes/routes.dart';
import 'package:iWarden/screens/auth/login_screen.dart';
import 'package:iWarden/settings/app_settings.dart';
import 'package:iWarden/theme/theme.dart';
import 'package:iWarden/widgets/layouts/check_sync_data_layout.dart';
import 'package:iWarden/widgets/layouts/network_layout.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  await dotenv.load(fileName: ".env").then((value) => {});
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  //firebase Crashlytics config
  if (ConfigEnvironmentVariable.environment.toString() != 'local') {
    //test err
    // FirebaseCrashlytics.instance.crash();
    //Action Check
    await Firebase.initializeApp();
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardensInfo()),
        ChangeNotifierProvider(create: (_) => Locations()),
        ChangeNotifierProvider(
          create: (_) => print_issue.PrintIssueProviders(),
        ),
        ChangeNotifierProvider(create: (_) => ContraventionProvider()),
        ChangeNotifierProvider(create: (_) => SyncData()),
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
          myWidget: FutureBuilder<bool>(
            future: authentication.isAuth(),
            builder: ((context, snapshot) {
              if (snapshot.data == true) {
                return const CheckSyncDataLayout();
              } else {
                return const LoginScreen();
              }
            }),
          ),
        ),
      ),
      routes: routes,
    );
  }
}

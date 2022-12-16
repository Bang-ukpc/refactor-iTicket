import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart' as print_issue;
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/routes/routes.dart';
import 'package:iWarden/screens/connecting-status/connecting_screen.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/settings/app_settings.dart';
import 'package:iWarden/theme/theme.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final accessToken = await SharedPreferencesHelper.getStringValue(
      PreferencesKeys.accessToken,
    );
    const serviceURL = "http://192.168.1.200:7003";
    final dio = Dio();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] = accessToken;
    final wardenEventSendCurrentLocation = WardenEvent(
      type: TypeWardenEvent.TrackGPS.index,
      detail: "Warden's current location",
      latitude: inputData?['latitude'] ?? 0,
      longitude: inputData?['longitude'] ?? 0,
      wardenId: inputData?['wardenId'] ?? 0,
    );
    try {
      switch (task) {
        case sendCurrentLocationTask:
          await dio.post(
            '$serviceURL/wardenEvent',
            data: wardenEventSendCurrentLocation.toJson(),
          );
          break;
        default:
      }
    } catch (err) {
      Logger().e(err.toString());
      throw Exception(err);
    }
    return Future.value(true);
  });
}

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
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
    final appSetting = AppSettings();
    appSetting.settings();

    return MaterialApp(
      title: 'iWarden',
      theme: themeMain(),
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      home: Consumer<Auth>(
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
      routes: routes,
    );
  }
}

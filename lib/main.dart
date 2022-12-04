import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/layouts/auth_layout.dart';
import 'package:iWarden/providers/auth.dart';
import 'package:iWarden/providers/contraventions.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart' as print_issue;
import 'package:iWarden/providers/vehicle_info.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/connecting_screen.dart';
import 'package:iWarden/screens/login_screens.dart';
import 'package:iWarden/settings/app_settings.dart';
import 'package:iWarden/theme/theme.dart';
import 'package:provider/provider.dart';

import '../routes/routes.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: WardensInfo()),
        ChangeNotifierProvider.value(value: Locations()),
        ChangeNotifierProvider.value(value: print_issue.PrintIssueProviders()),
        ChangeNotifierProxyProvider<WardensInfo, Auth>(
          update: (_, wardensInfo, auth) => auth!..update(wardensInfo),
          create: (_) => Auth(),
        ),
        ChangeNotifierProxyProvider<Locations, VehicleInfo>(
          update: (_, locations, vehicleInfo) =>
              vehicleInfo!..update(locations),
          create: (_) => VehicleInfo(),
        ),
        ChangeNotifierProxyProvider<Locations, Contraventions>(
          update: (_, locations, contraventions) =>
              contraventions!..update(locations),
          create: (_) => Contraventions(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    final appSetting = AppSettings();
    appSetting.settings();

    return MaterialApp(
      title: 'iWarden',
      theme: themeMain(),
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      home: FutureBuilder(
        future: _fbApp,
        builder: ((context, snapshot) {
          if (snapshot.hasError) {
            print('You have an error! ${snapshot.error.toString()}');
            return const Text('Something went wrong!');
          } else if (snapshot.hasData) {
            return Consumer<Auth>(
              builder: (ctx, auth, _) => FutureBuilder(
                future: auth.isAuth(),
                builder: ((context, snapshot) {
                  if (snapshot.data == true) {
                    return const AuthLayout(child: ConnectingScreen());
                  } else {
                    return const LoginScreen();
                  }
                }),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }),
      ),
      routes: routes,
    );
  }
}

// void main() => runApp(
//       MultiProvider(
//         providers: [
//           ChangeNotifierProvider.value(value: Locations()),
//           ChangeNotifierProvider.value(value: PrintIssueProviders()),
//         ],
//         child: const MyApp(),
//       ),
//     );

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     // final appSetting = AppSettings();
//     // appSetting.settings();

//     return MaterialApp(
//       title: 'iWarden',
//       theme: themeMain(),
//       debugShowCheckedModeBanner: false,
//       home: const LocationScreen(),
//       initialRoute: LocationScreen.routeName,
//       routes: routes,
//     );
//   }
// }
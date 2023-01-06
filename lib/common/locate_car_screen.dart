import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/models/directions.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/screens/map-screen/map_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';

class LocateCarScreen extends StatefulWidget {
  static const routeName = '/locate-car';
  const LocateCarScreen({super.key});

  @override
  State<LocateCarScreen> createState() => _LocateCarScreenState();
}

class _LocateCarScreenState extends State<LocateCarScreen> {
  Directions? _info;

  // Future<void> goToDestination(
  //     {required LatLng sourceLocation, required LatLng destination}) async {
  //   final GoogleMapController controller = await _mapController.future;
  //   controller.animateCamera(
  //     CameraUpdate.newLatLngBounds(
  //       LatLngBounds(
  //         southwest: sourceLocation,
  //         northeast: destination,
  //       ),
  //       48,
  //     ),
  //   );
  //   final directions = await directionsRepository.getDirections(
  //       origin: sourceLocation, destination: destination);
  //   setState(() => _info = directions);
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //     final vehicleInfo =
  //         ModalRoute.of(context)!.settings.arguments as VehicleInformation;
  //     final sourceLocation = LatLng(
  //       currentLocationPosition.currentLocation?.latitude ?? 0,
  //       currentLocationPosition.currentLocation?.longitude ?? 0,
  //     );
  //     final destination = LatLng(
  //       vehicleInfo.Latitude,
  //       vehicleInfo.Longitude,
  //     );
  //     goToDestination(sourceLocation: sourceLocation, destination: destination);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final vehicleInfo =
        ModalRoute.of(context)!.settings.arguments as VehicleInformation;
    final destination = LatLng(
      vehicleInfo.Latitude,
      vehicleInfo.Longitude,
    );
    double distance = Geolocator.distanceBetween(
      currentLocationPosition.currentLocation?.latitude ?? 0,
      currentLocationPosition.currentLocation?.longitude ?? 0,
      vehicleInfo.Latitude,
      vehicleInfo.Longitude,
    );

    return Scaffold(
      appBar: const MyAppBar(
        title: "Locate car",
        automaticallyImplyLeading: true,
      ),
      drawer: const MyDrawer(),
      body: Column(children: [
        const SizedBox(
          height: 20,
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - 100,
          color: ColorTheme.white,
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      child: SvgPicture.asset(
                        "assets/svg/IconLocation3.svg",
                        width: 28,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      "${(((distance / 1000) / 15) * 60).ceil()}min (${(distance / 1000).toStringAsFixed(2)}km)",
                      style: CustomTextStyle.h4.copyWith(
                        color: ColorTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              MapScreen(
                screenHeight: MediaQuery.of(context).size.width < 400
                    ? screenHeight / 1.3
                    : screenHeight / 1.8,
                destination: destination,
                info: _info,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

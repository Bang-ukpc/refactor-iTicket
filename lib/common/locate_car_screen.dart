import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/number_format.dart';
import 'package:iWarden/models/directions.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/map-screen/map_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';

import '../helpers/my_navigator_observer.dart';

class LocateCarScreen extends StatefulWidget {
  static const routeName = '/locate-car';
  const LocateCarScreen({super.key});

  @override
  BaseStatefulState<LocateCarScreen> createState() => _LocateCarScreenState();
}

class _LocateCarScreenState extends BaseStatefulState<LocateCarScreen> {
  Directions? _info;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final vehicleInfo =
        ModalRoute.of(context)!.settings.arguments as VehicleInformation;

    CameraPosition initialPosition = CameraPosition(
      target: LatLng(
        vehicleInfo.Latitude,
        vehicleInfo.Longitude,
      ),
      zoom: 16,
    );

    double distance = Geolocator.distanceBetween(
      currentLocationPosition.currentLocation?.latitude ?? 0,
      currentLocationPosition.currentLocation?.longitude ?? 0,
      vehicleInfo.Latitude,
      vehicleInfo.Longitude,
    );

    String minWithKilometer() {
      double averageTime =
          ((distance / metersInKilometer) / averageSpeed * minutesInAnHour);
      double distanceInKilometers = distance / metersInKilometer;

      return "${numberFormatHelper.getNumberFormat(averageTime)}min (${numberFormatHelper.getNumberFormat(distanceInKilometers)}km)";
    }

    return Scaffold(
      bottomNavigationBar: const VersionName(),
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
          height: MediaQuery.of(context).size.height - 120,
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
                      minWithKilometer(),
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
                    ? screenHeight - 200
                    : screenHeight / 2,
                mapController: _controller,
                initialPosition: initialPosition,
                info: _info,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

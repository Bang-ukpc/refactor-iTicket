import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/models/directions.dart';

class MapScreen extends StatefulWidget {
  final double screenHeight;
  final CameraPosition initialPosition;
  final Directions? info;
  final Completer<GoogleMapController> mapController;

  const MapScreen({
    required this.screenHeight,
    required this.initialPosition,
    this.info,
    required this.mapController,
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // static LatLng? _initialPosition;

  // @override
  // void initState() {
  //   super.initState();
  //   _getUserLocation();
  // }

  // void _getUserLocation() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   setState(() {
  //     _initialPosition = LatLng(position.latitude, position.longitude);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.screenHeight,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          widget.mapController.complete(controller);
        },
        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
        myLocationEnabled: true,
        initialCameraPosition: widget.initialPosition,
        markers: {
          // Marker(
          //   icon: BitmapDescriptor.defaultMarkerWithHue(
          //     BitmapDescriptor.hueAzure,
          //   ),
          //   markerId: const MarkerId("source"),
          //   position: const LatLng(0, 0),
          // ),
          Marker(
            markerId: const MarkerId("destination"),
            position: widget.initialPosition.target,
          ),
        },
        // polylines: {
        //   if (widget.info != null)
        //     Polyline(
        //       polylineId: const PolylineId('overview_polyline'),
        //       color: Colors.blue,
        //       width: 6,
        //       points: widget.info!.polylinePoints
        //           .map((item) => LatLng(item.latitude, item.longitude))
        //           .toList(),
        //     ),
        // },
      ),
    );
  }
}

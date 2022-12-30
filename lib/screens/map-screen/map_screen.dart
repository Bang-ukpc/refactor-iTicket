import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/models/directions.dart';

class MapScreen extends StatefulWidget {
  final double screenHeight;
  final LatLng destination;
  final Directions? info;

  const MapScreen({
    required this.screenHeight,
    required this.destination,
    this.info,
    super.key,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // static LatLng? _initialPosition;
  final Completer<GoogleMapController> _controller = Completer();

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
    log('ao ma source location: ${currentLocationPosition.currentLocation.toString()}');
    log('ao ma destination: ${widget.destination}');

    return SizedBox(
      height: widget.screenHeight,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
        myLocationEnabled: true,
        initialCameraPosition: CameraPosition(
          target: widget.destination,
          zoom: 16,
        ),
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
            position: widget.destination,
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

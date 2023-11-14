import 'package:geolocator/geolocator.dart';

class CurrentLocation {
  Position? currentLocation;

  LocationSettings locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    forceLocationManager: true,
    distanceFilter: 10,
    intervalDuration: const Duration(seconds: 5),
  );

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    if (currentLocation != null) {
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? location) async {
        currentLocation = location;
      });
    } else {
      currentLocation = await Geolocator.getCurrentPosition();
      currentLocation ??= await Geolocator.getLastKnownPosition();
    }

    return currentLocation;
  }
}

final currentLocationPosition = CurrentLocation();

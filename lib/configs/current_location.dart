import 'package:geolocator/geolocator.dart';
import 'package:iWarden/helpers/logger.dart';

class CurrentLocation {
  Position? currentLocation;
  Logger logger = Logger<CurrentLocation>();

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
      logger.info('current position is not null');
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position? location) async {
        currentLocation = location;
      });
    } else {
      logger.info('current position is null');
      currentLocation = await Geolocator.getCurrentPosition();
      logger.info("get current position failed");
      currentLocation ??= await Geolocator.getLastKnownPosition();
    }

    return currentLocation;
  }
}

final currentLocationPosition = CurrentLocation();

import 'package:location/location.dart';

class CurrentLocation {
  LocationData? currentLocation;

  Future<LocationData?> getCurrentLocation() async {
    Location location = Location();

    await location.getLocation().then((location) {
      currentLocation = location;
    });
    return currentLocation;
  }
}

final currentLocationPosition = CurrentLocation();

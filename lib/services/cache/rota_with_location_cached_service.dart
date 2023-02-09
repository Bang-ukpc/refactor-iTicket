import 'package:iWarden/controllers/location_controller.dart';
import '../../models/location.dart';
import 'cache_service.dart';

class RotaWithLocationCachedService extends CacheService<RotaWithLocation> {
  late int wardenId;
  RotaWithLocationCachedService(int initWardenId)
      : super("cachedRotaWithLocations") {
    wardenId = initWardenId;
  }

  @override
  syncFromServer() async {
    var filter = ListLocationOfTheDayByWardenIdProps(
        latitude: 0, longitude: 0, wardenId: wardenId);
    var rotaWithLocations = await locationController.getAll(filter);
    set(rotaWithLocations);
  }
}

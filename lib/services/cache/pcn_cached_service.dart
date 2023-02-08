import '../../models/contravention.dart';
import 'cache_service.dart';

class PCNCachedService extends CacheService<Contravention> {
  PCNCachedService() : super("PCN");
}

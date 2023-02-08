import 'package:iWarden/models/base_model.dart';
import 'package:iWarden/services/cache/cache_service.dart';

abstract class ILocalService<T extends Identifiable> {
  syncAll();
  sync(T t);
}

abstract class BaseLocalService<T extends Identifiable> extends CacheService<T>
    implements ILocalService<T> {
  BaseLocalService(super.initLocalKey);
}

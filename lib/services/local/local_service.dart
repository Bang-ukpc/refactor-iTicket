import 'package:iWarden/models/base_model.dart';
import 'package:iWarden/services/cache/cache_service.dart';

import '../../models/log.dart';

abstract class ILocalService<T extends Identifiable> {
  syncAll(bool isStopSyncing,
      [Function(int current, int total, [SyncLog? log])? syncStatusCallBack]);
  Future<T?> sync(T t);
}

abstract class BaseLocalService<T extends Identifiable> extends CacheService<T>
    implements ILocalService<T> {
  bool isSyncing = false;
  BaseLocalService(super.initLocalKey);

  @override
  syncAll(bool? isStopSyncing,
      [Function(int current, int total, [SyncLog? log])?
          syncStatusCallBack]) async {
    if (isSyncing) {
      print("Is syncing");
      return;
    }
    isSyncing = true;

    final items = await getAll();
    print('[SYNC ALL] ${items.map((e) => e.Id)}');
    for (var item in items) {
      await sync(item);
    }

    isSyncing = false;
  }
}

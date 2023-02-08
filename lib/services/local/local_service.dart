abstract class ILocalService<T> {
  create(T t);
  syncAll();
  sync(T t);
  getAll() => List<T>;
  delete(T t);
}

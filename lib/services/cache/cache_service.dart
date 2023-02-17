// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/models/ContraventionService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/id_helper.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/base_model.dart';

abstract class ICacheService<T extends Identifiable> {
  syncFromServer();
  create(T t);
  bulkCreate(List<T> listT);
  delete(int id);
  get(int id);
  update(T t);
  set(List<T> listT);
  getAll() => List<T>;
  deleteAll();
}

class CacheService<T extends Identifiable> implements ICacheService<T> {
  late String localKey;

  CacheService(String initLocalKey) {
    localKey = initLocalKey;
  }

  @override
  create(T t) async {
    t.Id ??= idHelper.generateId();
    final items = await getAll();
    items.add(t);
    await set(items);
  }

  @override
  bulkCreate(List<T> listT) async {
    final items = await getAll();
    items.addAll(listT);
    await set(items);
  }

  @override
  delete(int id) async {
    final items = await getAll();
    final updatedItems = items.where((element) {
      return element.Id != id;
    });
    await set(updatedItems.toList());
  }

  @override
  deleteAll() {
    SharedPreferencesHelper.removeStringValue(localKey);
  }

  @override
  Future<T?> get(int id) async {
    final items = await getAll();
    return items.firstWhereOrNull((element) => element.Id == id);
  }

  @override
  Future<List<T>> getAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? jsonItems =
        await SharedPreferencesHelper.getStringValue(localKey);

    if (jsonItems == null) return [];
    var decodedItems = json.decode(jsonItems) as List<dynamic>;
    return decodedItems.map((decodedItem) {
      if (decodedItem is String) {
        return jsonDecodeFactory.decode<T>(json.decode(decodedItem)) as T;
      } else {
        return jsonDecodeFactory.decode<T>(decodedItem) as T;
      }
    }).toList();
  }

  @override
  set(List<T> listT) async {
    await SharedPreferencesHelper.setStringValue(localKey, json.encode(listT));
  }

  @override
  update(T t) async {
    var items = await getAll();
    items = items.map((item) => item.Id == t.Id ? t : item).toList();
    await set(items);
  }

  @override
  Future<List<T>> syncFromServer() {
    throw UnimplementedError();
  }
}

Future<void> main(List<String> args) async {
  final cacheService = CacheService<ContraventionCreateWardenCommand>('a');
  var items = await cacheService.getAll();
  print(json.encode(items));
  print(items[0]);
}

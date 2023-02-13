// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:iWarden/factory/json_decode_factory.dart';
import 'package:iWarden/models/ContraventionService.dart';
import '../../helpers/id_helper.dart';
import '../../helpers/shared_preferences_helper.dart';
import '../../models/base_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    print('[DELETE VEHICLE INFO WITH ID] $id');
    final items = await getAll();
    print('[VEHICLE INFO LIST] ${items.map((e) => e.Id)}');
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
    return items.firstWhere((element) => element.Id == id);
  }

  @override
  Future<List<T>> getAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final String? jsonItems =
        await SharedPreferencesHelper.getStringValue(localKey);
    // const jsonItems =
    //     '[{"Id":1,"ZoneId":1,"ContraventionReference":"123123","Plate":"123123","VehicleMake":"123","VehicleColour":"213","ContraventionReasonCode":"36","EventDateTime":"2023-02-06T00:00:00.000Z","FirstObservedDateTime":"2023-02-06T00:00:00.000Z","WardenId":1,"BadgeNumber":"1","Longitude":0,"Latitude":0,"LocationAccuracy":1,"WardenComments":""}]';

    if (jsonItems == null) return [];
    var decodedItems = json.decode(jsonItems) as List<dynamic>;
    print('[GET ALL] $decodedItems');
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
    final items = await getAll();
    items.map((item) => item.Id == t.Id ? t : item);
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

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:iWarden/factory/json_decode_factory.dart';

import '../../helpers/shared_preferences_helper.dart';
import '../../models/base_model.dart';
import '../../models/vehicle_information.dart';
// import 'dart:developer';
// import 'package:iWarden/models/vehicle_information.dart';
// import '../../helpers/shared_preferences_helper.dart';

abstract class ICacheService<T extends Identifiable> {
  create(T t);
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
    final items = await getAll();
    items.add(t);
    set(items);
  }

  @override
  delete(int id) async {
    final items = await getAll();
    final updatedItems = items.where((element) => element.Id != id);
    set(updatedItems.toList());
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
    final String? jsonItems =
        await SharedPreferencesHelper.getStringValue(localKey);
    // const jsonItems = '[{"ExpiredAt":"2023-02-06T00:00:00.000Z","Plate":"12323","ZoneId":1,"LocationId":1,"BayNumber":"12","Type":0,"Latitude":0,"Longitude":0,"CarLeft":false,"EvidencePhotos":[]}]';

    if (jsonItems == null) return [];
    var decodedItems = json.decode(jsonItems) as List<dynamic>;
    return decodedItems
        .map((decodedItem) => jsonDecodeFactory.decode<T>(decodedItem) as T)
        .toList();
  }

  @override
  set(List<T> listT) {
    SharedPreferencesHelper.setStringValue(localKey, json.encode(listT));
  }

  @override
  update(T t) async {
    final items = await getAll();
    items.map((item) => item.Id == t.Id ? t : item);
  }
}

Future<void> main(List<String> args) async {
  final cacheService = CacheService<VehicleInformation>('a');
  var items = await cacheService.getAll();
  print(items[0].ExpiredAt);
}

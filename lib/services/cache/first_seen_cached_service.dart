import 'dart:convert';

import 'package:iWarden/helpers/time_helper.dart';
import 'package:iWarden/models/pagination.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/services/local/created_vehicle_data_local_service.dart';

import '../../controllers/index.dart';
import 'cache_service.dart';

class FirstSeenCachedService extends CacheService<VehicleInformation> {
  late int _zoneId;
  FirstSeenCachedService(int zoneId) : super("cacheFirstSeenItems_$zoneId") {
    _zoneId = zoneId;
  }

  Future<List<VehicleInformation>> getListActive() async {
    var items = await getAllWithCreatedOnTheOffline();
    return items.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  DateTime.now(),
                ),
              ),
            ),
            i.ExpiredAt,
          ) >
          0;
    }).toList();
  }

  Future<List<VehicleInformation>> getListExpired() async {
    var items = await getAllWithCreatedOnTheOffline();
    return items.where((i) {
      return timeHelper.daysBetween(
            i.Created!.add(
              Duration(
                minutes: timeHelper.daysBetween(
                  i.Created as DateTime,
                  DateTime.now(),
                ),
              ),
            ),
            i.ExpiredAt,
          ) <=
          0;
    }).toList();
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkVehicleInfoController
        .getVehicleInfoList(
            vehicleInfoType: VehicleInformationType.FIRST_SEEN.index,
            zoneId: _zoneId,
            page: 1,
            pageSize: 1000)
        .catchError((err) async {
      var vehicleInfos = await getAll();
      return Pagination(
          page: 0,
          pageSize: 1000,
          total: vehicleInfos.length,
          totalPages: 1,
          rows: vehicleInfos);
    });
    await set(paging.rows as List<VehicleInformation>);
    return paging.rows as List<VehicleInformation>;
  }

  Future<List<VehicleInformation>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItem = await createdVehicleDataLocalService.getAllFirstSeen();
    return [...issuedItem, ...cachedItems];
  }
}

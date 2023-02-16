import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:iWarden/services/cache/contravention_reason_cached_service.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';
import '../../controllers/index.dart';
import '../../models/ContraventionService.dart';
import '../../models/contravention.dart';
import '../local/issued_pcn_local_service.dart';
import 'cache_service.dart';

class ContraventionCachedService extends CacheService<Contravention> {
  late int _zoneId;
  ContraventionCachedService(int zoneId)
      : super("cachedContraventions_$zoneId") {
    _zoneId = zoneId;
  }

  @override
  syncFromServer() async {
    var paging = await weakNetworkContraventionController
        .getContraventionServiceList(zoneId: _zoneId, page: 1, pageSize: 1000);
    print('[Contraventions] ${paging.rows.map((e) => json.encode(e))}');
    await set(paging.rows as List<Contravention>);
    return paging.rows as List<Contravention>;
  }

  Future<Contravention> convertIssuesContraventionToCachedContravention(
      ContraventionCreateWardenCommand i) async {
    var contraventionPhotos = (await issuedPcnPhotoLocalService
            .listByContraventionReference(i.ContraventionReference))
        .map((e) => issuedPcnPhotoLocalService.toContraventionPhoto(e))
        .toList();
    var contraventionService = ContraventionReasonCachedService(_zoneId);
    var contraventionReasons = await contraventionService.getAll();

    return Contravention(
      reference: i.ContraventionReference,
      created: DateTime.now(),
      id: i.Id,
      plate: i.Plate,
      colour: i.VehicleColour,
      make: i.VehicleMake,
      eventDateTime: i.EventDateTime,
      zoneId: i.ZoneId,
      reason: Reason(
        code: i.ContraventionReasonCode,
        contraventionReasonTranslations: contraventionReasons
            .where((e) => e.code == i.ContraventionReasonCode)
            .toList(),
      ),
      contraventionEvents: [
        ContraventionEvents(
          contraventionId: i.Id,
          detail: i.WardenComments,
        )
      ],
      contraventionDetailsWarden: ContraventionDetailsWarden(
        FirstObserved: i.FirstObservedDateTime,
        ContraventionId: i.Id,
        WardenId: i.WardenId,
        IssuedAt: i.EventDateTime,
      ),
      type: i.TypePCN,
      contraventionPhotos: contraventionPhotos,
    );
  }

  Future<bool> isExistedWithIn24h(
      {required String vrn,
      required int zoneId,
      required String contraventionType}) async {
    var items = await getAllWithCreatedOnTheOffline();
    var findVRNExits = items.firstWhereOrNull((e) =>
        e.plate == vrn &&
        e.zoneId == zoneId &&
        e.reason?.code == contraventionType);
    if (findVRNExits != null) {
      var date = DateTime.now();
      var timeMayIssue = findVRNExits.created!.add(const Duration(hours: 24));
      if (date.isBefore(timeMayIssue)) {
        return false;
      }
    }
    return true;
  }

  Future<List<Contravention>> getIssuedContraventions(int zoneId) async {
    var issuedItems = await issuedPcnLocalService.getAll();
    issuedItems =
        issuedItems.where((element) => element.ZoneId == zoneId).toList();
    return await Future.wait(issuedItems.map(
        (i) async => await convertIssuesContraventionToCachedContravention(i)));
  }

  Future<List<Contravention>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItems = await getIssuedContraventions(_zoneId);
    var items = [...issuedItems, ...cachedItems];
    // TODO: sort by created as desc
    var itemSort = items..sort((i1, i2) => i2.created!.compareTo(i1.created!));
    return itemSort;
  }
}

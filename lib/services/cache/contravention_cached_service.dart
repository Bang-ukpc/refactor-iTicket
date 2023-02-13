import 'dart:convert';
import 'package:iWarden/services/cache/contravention_reason_cached_service.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/services/local/issued_pcn_photo_local_service.dart';

import '../../controllers/index.dart';
import '../../models/ContraventionService.dart';
import '../../models/contravention.dart';
import '../../models/pagination.dart';
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
        .getContraventionServiceList(zoneId: _zoneId, page: 1, pageSize: 1000)
        .catchError((err) async {
      var cachedItems = await getAll();
      return Pagination(
          page: 0,
          pageSize: 1000,
          total: cachedItems.length,
          totalPages: 1,
          rows: cachedItems);
    });
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

  Future<List<Contravention>> getIssuedContraventions() async {
    var issuedItems = await issuedPcnLocalService.getAll();
    return await Future.wait(issuedItems.map(
        (i) async => await convertIssuesContraventionToCachedContravention(i)));
  }

  Future<List<Contravention>> getAllWithCreatedOnTheOffline() async {
    var cachedItems = await getAll();
    var issuedItems = await getIssuedContraventions();
    return [...issuedItems, ...cachedItems];
  }
}

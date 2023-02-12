import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/screens/home_overview.dart';
import 'package:iWarden/services/cache/factory/zone_cache_factory.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

class SyncZoneData extends StatefulWidget {
  static const routeName = '/sync-zone-data';
  const SyncZoneData({super.key});

  @override
  State<SyncZoneData> createState() => _SyncZoneDataState();
}

class _SyncZoneDataState extends State<SyncZoneData> {
  late ZoneCachedServiceFactory zoneCachedServiceFactory;

  Future<void> syncZoneData() async {
    await zoneCachedServiceFactory.contraventionCachedService.syncFromServer();
    await zoneCachedServiceFactory.contraventionReasonCachedService
        .syncFromServer();
    await zoneCachedServiceFactory.firstSeenCachedService.syncFromServer();
    await zoneCachedServiceFactory.gracePeriodCachedService.syncFromServer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final locationProvider = Provider.of<Locations>(context, listen: false);
      print("[SYNC ZONE DATA] with zoneID is ${locationProvider.zone?.Id}");
      zoneCachedServiceFactory =
          ZoneCachedServiceFactory(locationProvider.zone?.Id ?? 0);
      syncZoneData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: SizedBox(
        height: 46,
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
                HomeOverview.routeName, (Route<dynamic> route) => false);
          },
          icon: SvgPicture.asset('assets/svg/IconNextBottom.svg'),
          label: Text(
            'Check in',
            style:
                CustomTextStyle.h6.copyWith(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      body: Container(
        child: Text('Sync zone data'),
      ),
    );
  }
}

import 'dart:async';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/common/version_name.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/my_navigator_observer.dart';
import 'package:iWarden/helpers/number_format.dart';
import 'package:iWarden/helpers/user_info.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/directions.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/operational_period.dart';
import 'package:iWarden/models/zone.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/time_ntp.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/map-screen/map_screen.dart';
import 'package:iWarden/screens/read_regulation_screen.dart';
import 'package:iWarden/services/cache/factory/cache_factory.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/info_drawer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const metersInKilometer = 1000;
const averageSpeed = 15;
const minutesInAnHour = 60;

class LocationScreen extends StatefulWidget {
  static const routeName = '/location';
  const LocationScreen({super.key});

  @override
  BaseStatefulState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends BaseStatefulState<LocationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<RotaWithLocation> locationWithRotaList = [];
  List<RotaWithLocation> listFilter = [];
  List<RotaWithLocation> listFilterByRota = [];
  List<LocationWithZones> locationList = [];
  Directions? _info;
  bool isLoading = true;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Position? currentLocation;
  late CachedServiceFactory cachedServiceFactory;
  DateTime getNowNTP = DateTime.now();

  String formatRotaShift(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  Future<void> getRotas() async {
    List<RotaWithLocation> rotas = [];
    List<LocationWithZones> locationsFromCached = [];
    try {
      await cachedServiceFactory.rotaWithLocationCachedService.syncFromServer();
      if (userInfo.isStsUser) {
        locationsFromCached = await cachedServiceFactory
            .rotaWithLocationCachedService
            .getAllLocations();
      } else {
        rotas =
            await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      }
    } catch (e) {
      if (userInfo.isStsUser) {
        locationsFromCached = await cachedServiceFactory
            .rotaWithLocationCachedService
            .getAllLocations();
      } else {
        rotas =
            await cachedServiceFactory.rotaWithLocationCachedService.getAll();
      }
    }
    setState(() {
      locationWithRotaList = rotas;
      locationList = locationsFromCached;
      isLoading = false;
    });
  }

  getLocalDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  setTimeNTP() async {
    DateTime now = await timeNTP.getTimeWithUKTime();
    setState(() {
      getNowNTP = now;
    });
  }

  List<RotaWithLocation> rotaList(List<RotaWithLocation> list) {
    final filterRotaShiftByNow = list.where(
      (location) {
        DateTime timeFrom =
            DateTime.parse(getLocalDate(location.timeFrom as DateTime));
        DateTime timeTo =
            DateTime.parse(getLocalDate(location.timeTo as DateTime));
        return checkTimeoutRota(timeFrom, timeTo);
      },
    ).toList();
    filterRotaShiftByNow.sort(
      (i1, i2) => DateTime.parse(getLocalDate(i1.timeFrom as DateTime))
          .compareTo(DateTime.parse(getLocalDate(i2.timeFrom as DateTime))),
    );
    list.sort(
      (i1, i2) => DateTime.parse(getLocalDate(i1.timeFrom as DateTime))
          .compareTo(DateTime.parse(getLocalDate(i2.timeFrom as DateTime))),
    );
    setState(() {
      listFilter = filterRotaShiftByNow;
    });
    return list;
  }

  Logger logger = Logger<LocationScreen>();
  bool checkTimeoutFrom(DateTime date) {
    DateTime now = DateTime.parse(
        getLocalDate(getNowNTP.add(const Duration(minutes: 30))));
    return now.isAfter(date);
  }

  bool checkTimeoutTo(DateTime date) {
    DateTime now = DateTime.parse(
        getLocalDate(getNowNTP.add(const Duration(minutes: -30))));
    return now.isBefore(date);
  }

  bool checkTimeoutRota(DateTime from, DateTime to) {
    bool checkTimeForm = checkTimeoutFrom(DateTime.parse(getLocalDate(from)));
    bool checkTimeTo = checkTimeoutTo(DateTime.parse(getLocalDate(to)));
    return (checkTimeForm && checkTimeTo);
  }

  List<RotaWithLocation> locationListFilterByRota(
      DateTime? from, DateTime? to) {
    DateTime rotaTimeFrom = DateTime.parse(getLocalDate(from as DateTime));
    DateTime rotaTimeTo = DateTime.parse(getLocalDate(to as DateTime));

    final rotaListFilter = locationWithRotaList.where(
      (location) {
        DateTime timeFrom =
            DateTime.parse(getLocalDate(location.timeFrom as DateTime));
        DateTime timeTo =
            DateTime.parse(getLocalDate(location.timeTo as DateTime));
        return rotaTimeFrom.compareTo(timeFrom) >= 0 &&
            rotaTimeTo.compareTo(timeTo) <= 0;
      },
    ).toList();

    setState(() {
      listFilterByRota = rotaListFilter;
    });
    return listFilterByRota;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await setTimeNTP();
      await currentLocationPosition.getCurrentLocation();
      if (!mounted) return;
      final locations = Provider.of<Locations>(context, listen: false);
      locations.resetLocationWithZones();
      final wardensProvider = Provider.of<WardensInfo>(context, listen: false);
      cachedServiceFactory =
          CachedServiceFactory(wardensProvider.wardens?.Id ?? 0);
      await getRotas();
      rotaList(locationWithRotaList);
      if (userInfo.isStsUser) {
        if (locationList.isNotEmpty) {
          final selectedLocation = locationList[0];

          locations.onSelectedLocation(selectedLocation);
          locations.onSelectedZone(selectedLocation.Zones!.isNotEmpty
              ? selectedLocation.Zones![0]
              : null);
        }
      } else {
        if (listFilter.isNotEmpty) {
          final rotaSelected = listFilter[0];
          locationListFilterByRota(rotaSelected.timeFrom, rotaSelected.timeTo);

          final selectedLocation = listFilterByRota[0].locations![0];
          locations.onSelectedRotaShift(rotaSelected);
          locations.onSelectedLocation(selectedLocation);
          locations.onSelectedZone(selectedLocation.Zones!.isNotEmpty
              ? selectedLocation.Zones![0]
              : null);
        }
      }
    });
  }

  @override
  void dispose() {
    locationWithRotaList.clear();
    listFilter.clear();
    listFilterByRota.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final locations = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    double handelDistanceInMeters(
        {required double endLatitude, required double endLongitude}) {
      return Geolocator.distanceBetween(
          currentLocationPosition.currentLocation?.latitude ?? 0,
          currentLocationPosition.currentLocation?.longitude ?? 0,
          endLatitude,
          endLongitude);
    }

    String minWithKilometer() {
      double distance = handelDistanceInMeters(
          endLatitude: locations.location?.Latitude ?? 0,
          endLongitude: locations.location?.Longitude ?? 0);

      double averageTime =
          ((distance / metersInKilometer) / averageSpeed * minutesInAnHour);
      double distanceInKilometers = distance / metersInKilometer;

      if (listFilter.isNotEmpty || locationList.isNotEmpty) {
        return "${numberFormatHelper.getNumberFormat(averageTime)}min (${numberFormatHelper.getNumberFormat(distanceInKilometers)}km)";
      } else {
        return "0min (0.0km)";
      }
    }

    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            buttonCancel: false,
            title: Text(
              "Warning",
              style: CustomTextStyle.h4.copyWith(
                  color: ColorTheme.danger, fontWeight: FontWeight.w600),
            ),
            subTitle: const Text(
              "You are out of the check in zone, please go to the location.",
              style: CustomTextStyle.h5,
              textAlign: TextAlign.center,
            ),
            func: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorTheme.danger,
              ),
              child: Text("Accept",
                  style: CustomTextStyle.h5.copyWith(
                    color: Colors.white,
                  )),
              onPressed: () async {
                await currentLocationPosition.getCurrentLocation();
                if (!mounted) return;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          );
        },
      );
    }

    CameraPosition initialPosition = CameraPosition(
      target: LatLng(
        locations.location?.Latitude ?? 0,
        locations.location?.Longitude ?? 0,
      ),
      zoom: 16,
    );

    void setZoneWhenSelectedLocation(LocationWithZones locationSelected) {
      locations.onSelectedZone(
        locationSelected.Zones!.isNotEmpty ? locationSelected.Zones![0] : null,
      );
    }

    Future<void> goToDestination(
        {required double latitude, required double longitude}) async {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
          latitude,
          longitude,
        ),
        zoom: 16,
      )));
    }

    List<LocationWithZones> getLocations() {
      if (!userInfo.isStsUser) {
        return locations.rotaShift != null
            ? locations.rotaShift!.locations!.isNotEmpty
                ? locations.rotaShift!.locations as List<LocationWithZones>
                : []
            : [];
      }
      return locationList;
    }

    Future<void> refresh() async {
      await setTimeNTP();
      await getRotas();
      rotaList(locationWithRotaList);
      await currentLocationPosition.getCurrentLocation();
      if (userInfo.isStsUser) {
        if (locationList.isNotEmpty) {
          final selectedLocation = locationList[0];
          locations.onSelectedLocation(selectedLocation);
          locations.onSelectedZone(selectedLocation.Zones!.isNotEmpty
              ? selectedLocation.Zones![0]
              : null);
          handelDistanceInMeters(
              endLatitude: selectedLocation.Latitude ?? 0,
              endLongitude: selectedLocation.Longitude ?? 0);
          goToDestination(
              latitude: selectedLocation.Latitude ?? 0,
              longitude: selectedLocation.Longitude ?? 0);
        } else {
          locations.resetLocationWithZones();
        }
      } else {
        if (listFilter.isNotEmpty) {
          final rotaSelected = listFilter[0];
          locationListFilterByRota(rotaSelected.timeFrom, rotaSelected.timeTo);
          locations.onSelectedRotaShift(rotaSelected);

          final selectedLocation = listFilterByRota[0].locations;
          locations.onSelectedLocation(
              selectedLocation!.isNotEmpty ? selectedLocation[0] : null);
          handelDistanceInMeters(
              endLatitude: selectedLocation[0].Latitude ?? 0,
              endLongitude: selectedLocation[0].Longitude ?? 0);
          goToDestination(
              latitude: selectedLocation[0].Latitude ?? 0,
              longitude: selectedLocation[0].Longitude ?? 0);
          locations.onSelectedZone(selectedLocation.isNotEmpty
              ? selectedLocation[0].Zones!.isNotEmpty
                  ? selectedLocation[0].Zones![0]
                  : null
              : null);
        } else {
          locations.resetLocationWithZones();
        }
      }
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          bottomNavigationBar: const VersionName(),
          bottomSheet: SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(ColorTheme.primary),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                // checkTimeoutRota(DateTime.now(), DateTime.now());
                // logger.info(textTimeoutRota(DateTime.now(), DateTime.now()));
                final isValid = _formKey.currentState!.validate();
                if (!isValid) {
                  return;
                } else {
                  if (handelDistanceInMeters(
                          endLatitude: locations.location?.Latitude ?? 0,
                          endLongitude: locations.location?.Longitude ?? 0) <=
                      1609.344) {
                    Navigator.of(context)
                        .pushNamed(ReadRegulationScreen.routeName);
                  } else {
                    showMyDialog();
                  }
                }

                _formKey.currentState!.save();
                return;
              },
              icon: SvgPicture.asset('assets/svg/IconNext.svg',
                  color: ColorTheme.white),
              label: Text(
                'Next',
                style: CustomTextStyle.h5.copyWith(
                  color: ColorTheme.white,
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: statusBarHeight,
                  ),
                  InfoDrawer(
                    assetImage: wardensProvider.wardens?.Picture ??
                        "assets/images/userAvatar.png",
                    name: "Hi ${wardensProvider.wardens?.FullName ?? ""}",
                    location: null,
                    zone: null,
                    isDrawer: false,
                    isLogout: true,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    child: isLoading == false
                        ? Column(
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Please select your location for this shift',
                                      style: CustomTextStyle.body1.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (!userInfo.isStsUser)
                                      Column(
                                        children: [
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          SizedBox(
                                            child: DropdownSearch<
                                                RotaWithLocation>(
                                              dropdownBuilder:
                                                  (context, selectedItem) {
                                                return Text(
                                                    selectedItem == null
                                                        ? "Select rota shift"
                                                        : '${formatRotaShift(selectedItem.timeFrom as DateTime)} - ${formatRotaShift(selectedItem.timeTo as DateTime)}',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: selectedItem ==
                                                                null
                                                            ? ColorTheme.grey400
                                                            : ColorTheme
                                                                .textPrimary));
                                              },
                                              dropdownDecoratorProps:
                                                  DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    dropDownButtonStyle
                                                        .getInputDecorationCustom(
                                                  labelText: const Text(
                                                    'My rota shift',
                                                  ),
                                                  hintText: 'Select rota shift',
                                                ),
                                              ),
                                              items: rotaList(
                                                  locationWithRotaList),
                                              selectedItem:
                                                  listFilter.isNotEmpty
                                                      ? listFilter[0]
                                                      : null,
                                              itemAsString: (item) =>
                                                  '${formatRotaShift(item.timeFrom as DateTime)} - ${formatRotaShift(item.timeTo as DateTime)}',
                                              popupProps: PopupProps.menu(
                                                disabledItemFn: (item) =>
                                                    !checkTimeoutRota(
                                                        item.timeFrom
                                                            as DateTime,
                                                        item.timeTo
                                                            as DateTime),
                                                fit: FlexFit.loose,
                                                constraints:
                                                    const BoxConstraints(
                                                  maxHeight: 200,
                                                ),
                                                itemBuilder: (context, item,
                                                    isSelected) {
                                                  return DropDownItemRota(
                                                    timeout: checkTimeoutRota(
                                                        item.timeFrom
                                                            as DateTime,
                                                        item.timeTo
                                                            as DateTime),
                                                    title:
                                                        '${formatRotaShift(item.timeFrom as DateTime)} - ${formatRotaShift(item.timeTo as DateTime)}',
                                                    isSelected: item.Id ==
                                                        locations.rotaShift?.Id,
                                                  );
                                                },
                                              ),
                                              onChanged: (value) {
                                                RotaWithLocation
                                                    rotaShiftSelected =
                                                    locationWithRotaList
                                                        .firstWhere(
                                                  (item) =>
                                                      item.Id == value!.Id,
                                                );
                                                locations.onSelectedRotaShift(
                                                    rotaShiftSelected);
                                                locationListFilterByRota(
                                                  rotaShiftSelected.timeFrom,
                                                  rotaShiftSelected.timeTo,
                                                );
                                                locations.onSelectedLocation(
                                                  listFilterByRota[0]
                                                      .locations![0],
                                                );
                                                goToDestination(
                                                    latitude:
                                                        listFilterByRota[0]
                                                                .locations?[0]
                                                                .Latitude ??
                                                            0,
                                                    longitude:
                                                        listFilterByRota[0]
                                                                .locations?[0]
                                                                .Longitude ??
                                                            0);
                                                setZoneWhenSelectedLocation(
                                                    rotaShiftSelected
                                                        .locations![0]);
                                              },
                                              validator: ((value) {
                                                if (value == null) {
                                                  return 'Please select rota shift';
                                                }
                                                return null;
                                              }),
                                              autoValidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      child: DropdownSearch<LocationWithZones>(
                                        dropdownBuilder:
                                            (context, selectedItem) {
                                          return Text(
                                              selectedItem == null
                                                  ? "Select location"
                                                  : selectedItem.Name,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: selectedItem == null
                                                      ? ColorTheme.grey400
                                                      : ColorTheme
                                                          .textPrimary));
                                        },
                                        dropdownDecoratorProps:
                                            DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              dropDownButtonStyle
                                                  .getInputDecorationCustom(
                                            labelText: const Text('Location'),
                                            hintText: 'Select location',
                                          ),
                                        ),
                                        items: getLocations(),
                                        selectedItem: locations.location,
                                        itemAsString: (item) => item.Name,
                                        popupProps: PopupProps.menu(
                                          fit: FlexFit.loose,
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          itemBuilder:
                                              (context, item, isSelected) {
                                            return DropDownItem2(
                                              now: getNowNTP,
                                              title: item.Name,
                                              subTitle:
                                                  '${numberFormatHelper.getNumberFormat((handelDistanceInMeters(endLatitude: item.Latitude ?? 0, endLongitude: item.Longitude ?? 0) / metersInKilometer))}km',
                                              isSelected: item.Id ==
                                                  locations.location!.Id,
                                              operationalPeriodsList:
                                                  item.operationalPeriodHistories ??
                                                      [],
                                            );
                                          },
                                        ),
                                        onChanged: (value) async {
                                          LocationWithZones locationSelected;
                                          if (userInfo.isStsUser) {
                                            locationSelected = value!;
                                          } else {
                                            locationSelected = locations
                                                .rotaShift!.locations!
                                                .firstWhere(
                                                    (f) => f.Id == value!.Id);
                                          }
                                          locations.onSelectedLocation(
                                            locationSelected,
                                          );
                                          setZoneWhenSelectedLocation(
                                            locationSelected,
                                          );
                                          await goToDestination(
                                              latitude: value?.Latitude ?? 0,
                                              longitude: value?.Longitude ?? 0);
                                        },
                                        validator: ((value) {
                                          if (value == null) {
                                            return 'Please select location';
                                          }
                                          return null;
                                        }),
                                        autoValidateMode:
                                            AutovalidateMode.onUserInteraction,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      child: DropdownSearch<Zone>(
                                        dropdownBuilder:
                                            (context, selectedItem) {
                                          return Text(
                                              selectedItem == null
                                                  ? "Select zone"
                                                  : selectedItem.PublicName,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: selectedItem == null
                                                      ? ColorTheme.grey400
                                                      : ColorTheme
                                                          .textPrimary));
                                        },
                                        dropdownDecoratorProps:
                                            DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              dropDownButtonStyle
                                                  .getInputDecorationCustom(
                                            labelText: const Text('Zone'),
                                            hintText: 'Select zone',
                                          ),
                                        ),
                                        items: locations.location?.Zones ?? [],
                                        selectedItem: locations.zone,
                                        itemAsString: (item) => item.PublicName,
                                        popupProps: PopupProps.menu(
                                          fit: FlexFit.loose,
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          itemBuilder:
                                              (context, item, isSelected) =>
                                                  DropDownItem(
                                            title: item.PublicName,
                                            isSelected:
                                                item.Id == locations.zone!.Id,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          Zone zoneSelected = locations
                                              .location!.Zones!
                                              .firstWhere(
                                            (item) => item.Id == value!.Id,
                                          );
                                          locations
                                              .onSelectedZone(zoneSelected);
                                        },
                                        validator: ((value) {
                                          if (value == null) {
                                            return 'Please select zone';
                                          }
                                          return null;
                                        }),
                                        autoValidateMode:
                                            AutovalidateMode.onUserInteraction,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: Row(
                                        children: [
                                          Flexible(
                                            flex: 9,
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              color: ColorTheme.lighterPrimary,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svg/IconLocation2.svg",
                                                  ),
                                                  const SizedBox(
                                                    width: 14,
                                                  ),
                                                  Text(minWithKilometer(),
                                                      style: CustomTextStyle.h4
                                                          .copyWith(
                                                        color:
                                                            ColorTheme.primary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ))
                                                ],
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {},
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              color: ColorTheme.darkPrimary,
                                              child: SvgPicture.asset(
                                                "assets/svg/IconMaps.svg",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      child: locations.location != null
                                          ? MapScreen(
                                              screenHeight:
                                                  MediaQuery.of(context)
                                                              .size
                                                              .width <
                                                          400
                                                      ? screenHeight / 3
                                                      : screenHeight / 1.5,
                                              mapController: _controller,
                                              initialPosition: initialPosition,
                                              info: _info,
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DropDownItem extends StatelessWidget {
  final String title;
  final String? subTitle;
  final bool? isSelected;
  const DropDownItem({
    required this.title,
    this.subTitle,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: ColorTheme.grey300,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: subTitle != null ? 10 : 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: CustomTextStyle.body1.copyWith(
                color: isSelected == false
                    ? ColorTheme.textPrimary
                    : ColorTheme.primary,
                fontSize: 16,
              ),
            ),
            if (subTitle != null)
              Text(
                subTitle ?? '',
                style: CustomTextStyle.body2,
              ),
          ],
        ),
      ),
    );
  }
}

class DropDownItemRota extends StatelessWidget {
  final String title;
  final bool? isSelected;
  final bool timeout;
  const DropDownItemRota({
    required this.title,
    required this.timeout,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: ColorTheme.grey300,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
        child: Text(
          title,
          style: CustomTextStyle.body1.copyWith(
            color: isSelected == false
                ? !timeout
                    ? ColorTheme.grey600
                    : ColorTheme.textPrimary
                : ColorTheme.primary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class DropDownItem2 extends StatelessWidget {
  final String title;
  final String? subTitle;
  final bool? isSelected;
  final DateTime now;
  final List<OperationalPeriodHistories> operationalPeriodsList;
  const DropDownItem2({
    required this.title,
    this.subTitle,
    required this.now,
    this.isSelected = false,
    required this.operationalPeriodsList,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int currentMinutes = now.hour * 60 + now.minute;

    String formatOperationalPeriods(DateTime date) {
      return DateFormat('HH:mm').format(date);
    }

    Color getStatusColor({required int timeFrom, required int timeTo}) {
      if (currentMinutes <= timeFrom ||
          currentMinutes > timeFrom && currentMinutes <= timeTo) {
        return ColorTheme.success;
      }
      return ColorTheme.danger;
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: ColorTheme.grey300,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: subTitle != null ? 10 : 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Text(
                    title,
                    style: CustomTextStyle.body1.copyWith(
                        color: isSelected == false
                            ? ColorTheme.textPrimary
                            : ColorTheme.primary,
                        overflow: TextOverflow.ellipsis,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                if (subTitle != null)
                  Text(
                    subTitle ?? '',
                    style: CustomTextStyle.body2,
                  ),
              ],
            ),
            if (operationalPeriodsList.isNotEmpty)
              Column(
                children: operationalPeriodsList.map((e) {
                  return Column(
                    children: [
                      Text(
                        'Op ${formatOperationalPeriods(e.TimeFrom)} - ${formatOperationalPeriods(e.TimeTo)}',
                        style: CustomTextStyle.body2.copyWith(
                          color: getStatusColor(
                              timeFrom:
                                  e.TimeFrom.hour * 60 + e.TimeFrom.minute,
                              timeTo: e.TimeTo.hour * 60 + e.TimeTo.minute),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

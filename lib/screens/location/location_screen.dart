import 'dart:async';
import 'dart:developer';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/location_controller.dart';
import 'package:iWarden/models/directions.dart';
import 'package:iWarden/models/location.dart';
import 'package:iWarden/models/zone.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/map-screen/map_screen.dart';
import 'package:iWarden/screens/read_regulation_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/info_drawer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LocationScreen extends StatefulWidget {
  static const routeName = '/location';
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<LocationWithZones> locationList = [];
  List<LocationWithZones> listFilter = [];
  List<LocationWithZones> listFilterByRota = [];
  Directions? _info;
  bool check = false;
  bool isLoading = true;

  String formatRotaShift(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  Future<void> getLocationList(Locations locations, int wardenId) async {
    ListLocationOfTheDayByWardenIdProps listLocationOfTheDayByWardenIdProps =
        ListLocationOfTheDayByWardenIdProps(
      latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
      longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
      wardenId: wardenId,
    );

    await locationController
        .getAll(listLocationOfTheDayByWardenIdProps)
        .then((value) {
      setState(() {
        locationList = value;
        isLoading = false;
      });
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
    });
  }

  getLocalDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  List<LocationWithZones> rotaList(List<LocationWithZones> list) {
    DateTime date = DateTime.parse(getLocalDate(DateTime.now()));
    setState(() {
      listFilter = list.where(
        (location) {
          DateTime timeFrom =
              DateTime.parse(getLocalDate(location.From as DateTime));
          DateTime timeTo =
              DateTime.parse(getLocalDate(location.To as DateTime));
          return timeFrom.isAfter(date) ||
              (date.isAfter(timeFrom) && date.isBefore(timeTo));
        },
      ).toList();
    });
    return listFilter;
  }

  List<LocationWithZones> locationListFilterByRota(
      DateTime? from, DateTime? to) {
    DateTime rotaTimeFrom = DateTime.parse(getLocalDate(from as DateTime));
    DateTime rotaTimeTo = DateTime.parse(getLocalDate(to as DateTime));

    setState(() {
      listFilterByRota = locationList.where(
        (location) {
          DateTime timeFrom =
              DateTime.parse(getLocalDate(location.From as DateTime));
          DateTime timeTo =
              DateTime.parse(getLocalDate(location.To as DateTime));
          return rotaTimeFrom.compareTo(timeFrom) >= 0 &&
              rotaTimeTo.compareTo(timeTo) <= 0;
        },
      ).toList();
    });
    return listFilterByRota;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final locations = Provider.of<Locations>(context, listen: false);
      locations.resetLocationWithZones();
      final wardersProvider = Provider.of<WardensInfo>(context, listen: false);

      await getLocationList(locations, wardersProvider.wardens?.Id ?? 0);
      rotaList(locationList);
      if (listFilter.isNotEmpty) {
        locationListFilterByRota(listFilter[0].From, listFilter[0].To);
        locations.onSelectedRotaShift(
            MyRotaShift(From: listFilter[0].From, To: listFilter[0].To));
        locations.onSelectedLocation(listFilterByRota[0]);
        locations.onSelectedZone(listFilterByRota[0].Zones![0]);
      }
    });
  }

  @override
  void dispose() {
    locationList.clear();
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

    // final sourceLocation = LatLng(
    //   currentLocationPosition.currentLocation?.latitude ?? 0,
    //   currentLocationPosition.currentLocation?.longitude ?? 0,
    // );

    final destination = LatLng(
      locations.location?.Latitude ?? 0,
      locations.location?.Longitude ?? 0,
    );

    log('Location screen');

    void setZoneWhenSelectedLocation(LocationWithZones locationSelected) {
      locations.onSelectedZone(
        locationSelected.Zones!.isNotEmpty ? locationSelected.Zones![0] : null,
      );
    }

    // Future<void> goToDestination() async {
    //   final GoogleMapController controller = await _mapController.future;
    //   controller.animateCamera(
    //     CameraUpdate.newLatLngBounds(
    //       LatLngBounds(
    //         southwest: sourceLocation,
    //         northeast: destination,
    //       ),
    //       48,
    //     ),
    //   );
    //   final directions = await directionsRepository.getDirections(
    //       origin: sourceLocation, destination: destination);
    //   setState(() => _info = directions);
    // }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          bottomNavigationBar: BottomSheet2(buttonList: [
            BottomNavyBarItem(
              onPressed: () {
                final isValid = _formKey.currentState!.validate();
                if (!isValid) {
                  return;
                } else {
                  Navigator.of(context)
                      .pushNamed(ReadRegulationScreen.routeName);
                }

                _formKey.currentState!.save();
                return;
              },
              icon: SvgPicture.asset('assets/svg/IconNext.svg'),
              label: Text(
                'Next',
                style: CustomTextStyle.h6.copyWith(
                  color: ColorTheme.grey600,
                ),
              ),
            ),
          ]),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: statusBarHeight,
                ),
                InfoDrawer(
                  assetImage: wardensProvider.wardens?.Picture ??
                      "assets/images/userAvatar.png",
                  name: "Hello ${wardensProvider.wardens?.FullName ?? ""}",
                  location: null,
                  zone: null,
                  isDrawer: false,
                  isLogout: true,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: isLoading == false
                      ? Column(
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                      'Please select your location for this shift',
                                      style: CustomTextStyle.body1),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                    child: DropdownSearch<LocationWithZones>(
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            dropDownButtonStyle
                                                .getInputDecorationCustom(
                                          labelText:
                                              const Text('My rota shift'),
                                          hintText: 'Select rota shift',
                                        ),
                                      ),
                                      items: rotaList(locationList),
                                      selectedItem: listFilter.isNotEmpty
                                          ? listFilter[0]
                                          : null,
                                      itemAsString: (item) =>
                                          '${formatRotaShift(item.From as DateTime)} - ${formatRotaShift(item.To as DateTime)}',
                                      popupProps: PopupProps.menu(
                                        fit: FlexFit.loose,
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        itemBuilder:
                                            (context, item, isSelected) {
                                          return DropDownItem(
                                            title:
                                                '${formatRotaShift(item.From as DateTime)} - ${formatRotaShift(item.To as DateTime)}',
                                            isSelected: false,
                                          );
                                        },
                                      ),
                                      onChanged: (value) {
                                        LocationWithZones rotaShiftSelected =
                                            locationList.firstWhere(
                                          (item) => item.Id == value!.Id,
                                        );
                                        locations.onSelectedRotaShift(
                                          MyRotaShift(
                                            From: rotaShiftSelected.From,
                                            To: rotaShiftSelected.To,
                                          ),
                                        );
                                        locationListFilterByRota(
                                          rotaShiftSelected.From,
                                          rotaShiftSelected.To,
                                        );
                                        locations.onSelectedLocation(
                                          listFilterByRota[0],
                                        );
                                        setZoneWhenSelectedLocation(
                                            rotaShiftSelected);
                                      },
                                      validator: ((value) {
                                        if (value == null) {
                                          return 'Please select rota shift';
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
                                    child: DropdownSearch<LocationWithZones>(
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            dropDownButtonStyle
                                                .getInputDecorationCustom(
                                          labelText: const Text('Location'),
                                          hintText: 'Select location',
                                        ),
                                      ),
                                      items: listFilterByRota,
                                      selectedItem: listFilterByRota.isNotEmpty
                                          ? listFilterByRota[0]
                                          : null,
                                      itemAsString: (item) => item.Name,
                                      popupProps: PopupProps.menu(
                                        fit: FlexFit.loose,
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        itemBuilder:
                                            (context, item, isSelected) {
                                          return DropDownItem(
                                            title: item.Name,
                                            subTitle:
                                                'Distance: ${item.Distance}km',
                                            isSelected: false,
                                          );
                                        },
                                      ),
                                      onChanged: (value) {
                                        LocationWithZones locationSelected =
                                            locationList.firstWhere(
                                          (item) => item.Id == value!.Id,
                                        );
                                        locations.onSelectedLocation(
                                          locationSelected,
                                        );
                                        setZoneWhenSelectedLocation(
                                          locationSelected,
                                        );
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
                                      itemAsString: (item) => item.Name,
                                      popupProps: PopupProps.menu(
                                        fit: FlexFit.loose,
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        itemBuilder:
                                            (context, item, isSelected) =>
                                                DropDownItem(
                                          title: item.Name,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        Zone zoneSelected = locations
                                            .location!.Zones!
                                            .firstWhere(
                                          (item) => item.Id == value!.Id,
                                        );
                                        locations.onSelectedZone(zoneSelected);
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
                                                Text(
                                                  "${((locations.location?.Distance ?? 0) / 15 * 60).ceil()}min (${locations.location?.Distance ?? 0}km)",
                                                  style: CustomTextStyle.h4
                                                      .copyWith(
                                                    color: ColorTheme.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: locations.location != null
                                              ? () {
                                                  if (check == false) {
                                                    setState(() {
                                                      check = true;
                                                    });
                                                  }
                                                  // goToDestination();
                                                }
                                              : () {
                                                  CherryToast.error(
                                                    displayCloseButton: false,
                                                    title: Text(
                                                      'Please select location first',
                                                      style: CustomTextStyle.h5
                                                          .copyWith(
                                                              color: ColorTheme
                                                                  .danger),
                                                    ),
                                                    toastPosition:
                                                        Position.bottom,
                                                    borderRadius: 5,
                                                  ).show(context);
                                                },
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
                                        ? check == true
                                            ? MapScreen(
                                                screenHeight:
                                                    MediaQuery.of(context)
                                                                .size
                                                                .width <
                                                            400
                                                        ? screenHeight / 3
                                                        : screenHeight / 1.5,
                                                destination: destination,
                                                info: _info,
                                              )
                                            : const SizedBox()
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

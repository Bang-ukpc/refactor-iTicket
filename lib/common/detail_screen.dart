import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/locate_car_screen.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/controllers/vehicle_information_controller.dart';
import 'package:iWarden/models/first_seen.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/grace-period/index.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/detail_issue.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';

class DetailScreen extends StatefulWidget {
  final TypeFirstSeen type;

  const DetailScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as VehicleInformation;
    final calculateTime = CalculateTime();
    final List<String> imgList = [];
    final List<String> imgListFile = [];
    final vehicleInfoController = VehicleInfoController();

    for (int i = 0; i < args.EvidencePhotos!.length; i++) {
      imgList.add(
          '${ConfigEnvironmentVariable.azureContainerImageUrl}/${args.EvidencePhotos![i].BlobName}');
      imgListFile.add(args.EvidencePhotos![i].BlobName);
    }

    void onCarLeft() {
      VehicleInformation vehicleInfoToUpdate = VehicleInformation(
        ExpiredAt: args.ExpiredAt,
        Plate: args.Plate,
        ZoneId: args.ZoneId,
        LocationId: args.LocationId,
        BayNumber: args.BayNumber,
        Type: args.Type,
        Latitude: args.Latitude,
        Longitude: args.Longitude,
        CarLeft: true,
        EvidencePhotos: [],
        Id: args.Id,
      );

      showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            title: Text(
              "Confirm",
              style: CustomTextStyle.h4.copyWith(color: ColorTheme.danger),
            ),
            subTitle: const Text(
              "Confirm the vehicle has left.",
              style: CustomTextStyle.h5,
            ),
            func: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: ColorTheme.danger,
              ),
              child: Text("Proceed",
                  style: CustomTextStyle.h5.copyWith(
                    color: Colors.white,
                  )),
              onPressed: () async {
                await vehicleInfoController
                    .upsertVehicleInfo(vehicleInfoToUpdate)
                    .then((value) {
                  if (value != null) {
                    Navigator.of(context).pushReplacementNamed(
                      args.Type == 0
                          ? ActiveFirstSeenScreen.routeName
                          : GracePeriodList.routeName,
                    );
                  }
                });
              },
            ),
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: MyAppBar(
          title: args.Type == VehicleInformationType.FIRST_SEEN.index
              ? 'First seen details'
              : 'Consideration period details',
          automaticallyImplyLeading: true,
          onRedirect: () {
            args.Type == 0
                ? Navigator.of(context)
                    .popAndPushNamed(ActiveFirstSeenScreen.routeName)
                : Navigator.of(context)
                    .popAndPushNamed(GracePeriodList.routeName);
          },
        ),
        drawer: const MyDrawer(),
        bottomNavigationBar: BottomSheet2(
          buttonList: [
            BottomNavyBarItem(
              onPressed: onCarLeft,
              icon: SvgPicture.asset(
                'assets/svg/IconCar.svg',
                color: ColorTheme.white,
              ),
              label: 'Car left',
            ),
            if (widget.type == TypeFirstSeen.Expired)
              BottomNavyBarItem(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    IssuePCNFirstSeenScreen.routeName,
                    arguments: args,
                  );
                },
                icon: SvgPicture.asset(
                  'assets/svg/IconCharges2.svg',
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
                label: 'Issue PCN',
              ),
            BottomNavyBarItem(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  LocateCarScreen.routeName,
                  arguments: args,
                );
              },
              icon: SvgPicture.asset(
                'assets/svg/IconLocation.svg',
                width: 20,
                height: 20,
                color: Colors.white,
              ),
              label: 'Locate car',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.width < 400
                  ? 0
                  : ConstSpacing.bottom,
            ),
            child: Column(
              children: <Widget>[
                DetailIssue(
                  plate: args.Plate,
                  createdAt: args.Created as DateTime,
                  bayNumber: args.BayNumber,
                ),
                Container(
                  color: widget.type == TypeFirstSeen.Expired
                      ? ColorTheme.lightDanger
                      : ColorTheme.lightSuccess,
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  child: Text(
                    widget.type == TypeFirstSeen.Active
                        ? "Expiring in: ${calculateTime.getDuration(Duration(minutes: calculateTime.daysBetween(
                            args.Created!.add(
                              Duration(
                                minutes: calculateTime.daysBetween(
                                  args.Created as DateTime,
                                  DateTime.now(),
                                ),
                              ),
                            ),
                            args.ExpiredAt,
                          )))}"
                        : "Expired: ${calculateTime.getDurationExpiredIn(Duration(minutes: calculateTime.daysBetween(
                            args.ExpiredAt,
                            DateTime.now(),
                          )))}",
                    textAlign: TextAlign.center,
                    style: CustomTextStyle.h5.copyWith(
                      color: widget.type == TypeFirstSeen.Expired
                          ? ColorTheme.danger
                          : ColorTheme.success,
                    ),
                  ),
                ),
                AddImage(
                  displayTitle: false,
                  isSlideImage: true,
                  listImage: imgList,
                  listImageFile: imgListFile,
                  isCamera: false,
                  onAddImage: () async {
                    final results =
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CameraPicker(
                                  titleCamera: "Add",
                                  onDelete: (file) {
                                    return true;
                                  },
                                )));
                    if (results != null) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

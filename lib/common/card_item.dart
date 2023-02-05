import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/locate_car_screen.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/first_seen.dart';
import 'package:iWarden/models/vehicle_information.dart';
import 'package:iWarden/screens/first-seen/active_first_seen_screen.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class CardItem extends StatelessWidget {
  final VehicleInformation vehicleInfo;
  final int expiring;
  final TypeFirstSeen type;
  final String route;
  final Function onCarLeft;

  const CardItem({
    Key? key,
    required this.vehicleInfo,
    required this.expiring,
    required this.type,
    required this.route,
    required this.onCarLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calculateTime = CalculateTime();

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushReplacementNamed(route, arguments: vehicleInfo);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: ColorTheme.white),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleInfo.Plate.toUpperCase(),
                  style: CustomTextStyle.h4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                if (type == TypeFirstSeen.Expired)
                  Text(
                    "Expired: ${calculateTime.getDurationExpiredIn(Duration(minutes: expiring))} ago",
                    style: CustomTextStyle.h6.copyWith(
                      color: ColorTheme.danger,
                      fontSize: 14,
                    ),
                  ),
                if (type == TypeFirstSeen.Active)
                  Text(
                    "Expiring in: ${calculateTime.getDuration(Duration(minutes: expiring))}",
                    style: CustomTextStyle.h6.copyWith(
                      color: ColorTheme.danger,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Visited at: ${FormatDate().getLocalDate(vehicleInfo.Created as DateTime)}",
                  style: CustomTextStyle.h5.copyWith(color: ColorTheme.grey600),
                )
              ],
            ),
            Row(
              children: [
                if (type == TypeFirstSeen.Expired)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        IssuePCNFirstSeenScreen.routeName,
                        arguments: vehicleInfo,
                      );
                    },
                    icon: SvgPicture.asset(
                      "assets/svg/IconCharges2.svg",
                    ),
                  ),
                if (type == TypeFirstSeen.Expired)
                  const SizedBox(
                    width: 10,
                  ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      LocateCarScreen.routeName,
                      arguments: vehicleInfo,
                    );
                  },
                  icon: SvgPicture.asset(
                    "assets/svg/IconLocation.svg",
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {
                    onCarLeft();
                  },
                  icon: SvgPicture.asset("assets/svg/IconCar.svg"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//  ListTile(
//             title: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   vehicleInfo.Plate.toUpperCase(),
//                   style: CustomTextStyle.h4,
//                 ),
            //     Row(
            //       children: [
            //         if (type == TypeFirstSeen.Expired)
            //           IconButton(
            //             padding: EdgeInsets.zero,
            //             constraints:
            //                 const BoxConstraints(minWidth: 40, minHeight: 40),
            //             onPressed: () {
            //               Navigator.of(context).pushNamed(
            //                 IssuePCNFirstSeenScreen.routeName,
            //                 arguments: vehicleInfo,
            //               );
            //             },
            //             icon: SvgPicture.asset(
            //               "assets/svg/IconCharges2.svg",
            //             ),
            //           ),
            //         if (type == TypeFirstSeen.Expired)
            //           const SizedBox(
            //             width: 10,
            //           ),
            //         IconButton(
            //           padding: EdgeInsets.zero,
            //           constraints:
            //               const BoxConstraints(minWidth: 40, minHeight: 40),
            //           onPressed: () {
            //             Navigator.of(context).pushNamed(
            //               LocateCarScreen.routeName,
            //               arguments: vehicleInfo,
            //             );
            //           },
            //           icon: SvgPicture.asset(
            //             "assets/svg/IconLocation.svg",
            //           ),
            //         ),
            //         const SizedBox(
            //           width: 10,
            //         ),
            //         IconButton(
            //           padding: EdgeInsets.zero,
            //           constraints:
            //               const BoxConstraints(minWidth: 40, minHeight: 40),
            //           onPressed: () {
            //             onCarLeft();
            //           },
            //           icon: SvgPicture.asset("assets/svg/IconCar.svg"),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
                // if (type == TypeFirstSeen.Expired)
                //   Text(
                //     "Expired in: ${calculateTime.getDurationExpiredIn(Duration(minutes: expiring))} ago",
                //     style:
                //         CustomTextStyle.h6.copyWith(color: ColorTheme.danger),
                //   ),
                // if (type == TypeFirstSeen.Active)
                //   Text(
                //     "Expiring in: ${calculateTime.getDuration(Duration(minutes: expiring))}",
                //     style:
                //         CustomTextStyle.h6.copyWith(color: ColorTheme.danger),
                //   ),
                // Text(
                //   "Visited at: ${FormatDate().getLocalDate(vehicleInfo.Created as DateTime)}",
                //   style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
                // )
//               ],
//             ),
//             isThreeLine: true,
//           ),
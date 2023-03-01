import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/detail_car.dart';

import '../../helpers/my_navigator_observer.dart';
import '../../helpers/url_helper.dart';

class DetailParkingCommon extends StatefulWidget {
  final Contravention? contravention;
  final bool? isDisplayBottomNavigate;
  const DetailParkingCommon({
    this.contravention,
    this.isDisplayBottomNavigate = false,
    super.key,
  });

  @override
  BaseStatefulState<DetailParkingCommon> createState() =>
      _DetailParkingCommonState();
}

class _DetailParkingCommonState extends BaseStatefulState<DetailParkingCommon> {
  @override
  Widget build(BuildContext context) {
    List<ContraventionPhotos> contraventionImage =
        widget.contravention!.contraventionPhotos!.toList();

    final List<String?> images = contraventionImage.map((photo) {
      if (urlHelper.isLocalUrl(photo.blobName as String)) {
        return photo.blobName;
      } else {
        return urlHelper.toImageUrl(photo.blobName as String);
      }
    }).toList();

    return Scaffold(
      bottomNavigationBar: widget.isDisplayBottomNavigate == true
          ? BottomSheet2(buttonList: [
              BottomNavyBarItem(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(IssuePCNFirstSeenScreen.routeName);
                },
                icon: SvgPicture.asset(
                  "assets/svg/IconCharges2.svg",
                  width: 16,
                  color: Colors.white,
                ),
                label: 'Issue another PCN',
              ),
            ])
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            DetailCar(
              plate: widget.contravention!.plate as String,
              make: widget.contravention?.make,
              color: widget.contravention?.colour,
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Contravention",
                        style: CustomTextStyle.h4.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                          "Issued at: ${FormatDate().getLocalDate(widget.contravention?.eventDateTime as DateTime)}",
                          style: CustomTextStyle.body2.copyWith(
                            color: ColorTheme.success,
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    "Type: ${widget.contravention?.reason?.contraventionReasonTranslations?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                    style:
                        CustomTextStyle.h5.copyWith(color: ColorTheme.grey600),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    "Comment: ${widget.contravention?.contraventionEvents?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                    style:
                        CustomTextStyle.h5.copyWith(color: ColorTheme.grey600),
                  ),
                  const SizedBox(
                    height: 6,
                  )
                ],
              ),
            ),
            AddImage(
              listImage: images,
              isCamera: false,
              onAddImage: () {},
              isSlideImage: true,
              displayTitle: false,
            )
          ],
        ),
      ),
    );
  }
}

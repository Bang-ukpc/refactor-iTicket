import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/detail_car.dart';

class DetailParkingCommon extends StatefulWidget {
  final Contravention? contravention;
  final bool? isDisplayPrintPCN;
  final bool? isDisplayBottomNavigate;
  final bool? imagePreviewStatus;
  const DetailParkingCommon({
    this.contravention,
    this.isDisplayPrintPCN = false,
    this.isDisplayBottomNavigate = false,
    this.imagePreviewStatus = false,
    super.key,
  });

  @override
  State<DetailParkingCommon> createState() => _DetailParkingCommonState();
}

class _DetailParkingCommonState extends State<DetailParkingCommon> {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [];
    final List<String> imgListFile = [];
    List<ContraventionPhotos> contraventionImage =
        widget.contravention!.contraventionPhotos!.toList();
    for (int i = 0; i < contraventionImage.length; i++) {
      imgList.add(
          '${ConfigEnvironmentVariable.azureContainerImageUrl}/${contraventionImage[i].blobName}');
      imgListFile.add(contraventionImage[i].blobName ?? '');
    }

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
                ),
                label: const Text(
                  'Issue another PCN',
                  style: CustomTextStyle.h6,
                ),
              ),
            ])
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.isDisplayPrintPCN == true)
              Container(
                width: double.infinity,
                color: ColorTheme.darkPrimary,
                padding: const EdgeInsets.all(10),
                child: Center(
                    child: Text(
                  "Print PCN",
                  style: CustomTextStyle.h4.copyWith(color: Colors.white),
                )),
              ),
            DetailCar(
              plate: widget.contravention!.plate as String,
              make: widget.contravention?.make,
              color: widget.contravention?.colour,
              model: widget.contravention?.model,
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
                            color: ColorTheme.grey600,
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    "Type: ${widget.contravention?.reason?.contraventionReasonTranslations?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                    style:
                        CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    "Comment: ${widget.contravention?.contraventionEvents?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                    style:
                        CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
            AddImage(
              listImage: imgList,
              listImageFile: imgListFile,
              isCamera: false,
              onAddImage: () {},
              isSlideImage: true,
              displayTitle: false,
              imagePreview: widget.imagePreviewStatus,
            )
          ],
        ),
      ),
    );
  }
}

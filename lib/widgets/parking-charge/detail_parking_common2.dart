import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/parking-charges/issue_pcn_first_seen.dart';
import 'package:iWarden/screens/parking-charges/print_issue.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/step_issue_pcn.dart';

class DetailParkingCommon2 extends StatefulWidget {
  final Contravention? contravention;
  final bool? isDisplayBottomNavigate;
  final bool? imagePreviewStatus;
  const DetailParkingCommon2({
    this.contravention,
    this.isDisplayBottomNavigate = false,
    this.imagePreviewStatus = false,
    super.key,
  });

  @override
  State<DetailParkingCommon2> createState() => _DetailParkingCommon2State();
}

class _DetailParkingCommon2State extends State<DetailParkingCommon2> {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [];
    final List<String> imgListFile = [];
    List<ContraventionPhotos> contraventionImage = widget.contravention != null
        ? widget.contravention!.contraventionPhotos!.toList()
        : [];
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
                label: "Issue another PCN",
              ),
            ])
          : null,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: ColorTheme.white,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    "Issue PCN",
                    style: CustomTextStyle.h4
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepIssuePCN(
                      isActiveStep1: false,
                      onTap1: widget.contravention != null
                          ? () {
                              Navigator.of(context).pushReplacementNamed(
                                  IssuePCNFirstSeenScreen.routeName);
                            }
                          : null,
                      isActiveStep2: false,
                      isEnableStep3: true,
                      onTap2: widget.contravention != null
                          ? widget.contravention!.contraventionPhotos!
                                  .isNotEmpty
                              ? () {
                                  Navigator.of(context).pushReplacementNamed(
                                      PrintIssue.routeName);
                                }
                              : null
                          : null,
                      isActiveStep3: true,
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.contravention?.plate
                                      .toString()
                                      .toUpperCase() ??
                                  'No data',
                              style: CustomTextStyle.h3.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Make: ${widget.contravention?.make ?? "No data"}",
                                style: CustomTextStyle.h5.copyWith(
                                  color: ColorTheme.grey600,
                                ),
                              ),
                              Text(
                                "Color: ${widget.contravention?.colour ?? "No data"}",
                                style: CustomTextStyle.h5.copyWith(
                                  color: ColorTheme.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 5,
                    ),
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
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "Type: ${widget.contravention?.reason?.contraventionReasonTranslations?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                      style: CustomTextStyle.h5.copyWith(
                        color: ColorTheme.grey600,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "Comment: ${widget.contravention?.contraventionEvents?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                      style: CustomTextStyle.h5.copyWith(
                        color: ColorTheme.grey600,
                      ),
                    ),
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
      ),
    );
  }
}

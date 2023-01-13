import 'package:flutter/material.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/detail_car.dart';

class DetailParkingCommon extends StatefulWidget {
  final Contravention? contravention;
  final bool? isDisplayPrintPCN;
  const DetailParkingCommon({
    this.contravention,
    this.isDisplayPrintPCN = false,
    super.key,
  });

  @override
  State<DetailParkingCommon> createState() => _DetailParkingCommonState();
}

class _DetailParkingCommonState extends State<DetailParkingCommon> {
  @override
  Widget build(BuildContext context) {
    final List<String> imgList = [];
    List<ContraventionPhotos> contraventionImage =
        widget.contravention!.contraventionPhotos!.toList();
    for (int i = 0; i < contraventionImage.length; i++) {
      imgList.add(
          '${ConfigEnvironmentVariable.azureContainerImageUrl}/${contraventionImage[i].blobName}');
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.isDisplayPrintPCN == true)
            Container(
              width: double.infinity,
              color: ColorTheme.darkPrimary,
              padding: const EdgeInsets.all(8),
              child: Center(
                  child: Text(
                "Print PCN",
                style: CustomTextStyle.h4.copyWith(color: Colors.white),
              )),
            ),
          DetailCar(
            plate: widget.contravention!.plate as String,
            make: widget.contravention!.make as String,
            color: widget.contravention?.colour,
            model: widget.contravention?.model,
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            width: double.infinity,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Contravention",
                      style: CustomTextStyle.h4,
                    ),
                    Text(
                        "Issued at: ${FormatDate().getLocalDate(widget.contravention?.eventDateTime as DateTime)}",
                        style: CustomTextStyle.caption.copyWith(
                          color: ColorTheme.grey600,
                        )),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Type: ${widget.contravention?.reason?.contraventionReasonTranslations?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                  style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Comment: ${widget.contravention?.contraventionEvents?.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
                  style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
          AddImage(
            listImage: imgList,
            isCamera: false,
            onAddImage: () {},
            isSlideImage: true,
            displayTitle: false,
          )
        ],
      ),
    );
  }
}

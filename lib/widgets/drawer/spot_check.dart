import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/controllers/evidence_photo_controller.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class SpotCheck extends StatefulWidget {
  const SpotCheck({
    Key? key,
  }) : super(key: key);

  @override
  State<SpotCheck> createState() => _SpotCheckState();
}

class _SpotCheckState extends State<SpotCheck> {
  final evidencePhotoController = EvidencePhotoController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
      ),
      child: InkWell(
        // onTap: () async {
        //   final results = await Navigator.of(context).push(
        //     MaterialPageRoute(
        //       builder: (context) => CameraPicker(
        //         titleCamera: "Spot check",
        //         front: true,
        //         onDelete: (file) {
        //           return true;
        //         },
        //       ),
        //     ),
        //   );
        //   if (results != null) {
        //     await evidencePhotoController.uploadImage(results[0]);
        //   }
        // },
        onTap: () {
          Navigator.of(context).pop();
          CherryToast.info(
            displayCloseButton: false,
            title: Text(
              'Coming soon',
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.secondary),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SvgPicture.asset('assets/svg/IconSpotCheck.svg'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Spot check",
                style:
                    CustomTextStyle.h5.copyWith(color: ColorTheme.textPrimary),
              ),
            )
          ],
        ),
      ),
    );
  }
}

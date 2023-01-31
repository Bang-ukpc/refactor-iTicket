import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

import '../../common/my_dialog.dart';

class TakePhotoItem extends StatelessWidget {
  final int id;
  final String title;
  final File? image;
  final bool state;
  final VoidCallback? func;
  const TakePhotoItem(
      {required this.id,
      required this.title,
      required this.image,
      required this.state,
      this.func,
      super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> showMyDialog() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return MyDialog(
            title: Text(
              "Preview image",
              style: CustomTextStyle.h4.copyWith(fontWeight: FontWeight.w600),
            ),
            subTitle: const Text(
              "Please take enough proof photos to complete.",
              textAlign: TextAlign.center,
              style: CustomTextStyle.body1,
            ),
            func: ElevatedButton(
              child: const Text("Ok"),
              onPressed: () async {
                Navigator.of(context).pop();
                print(123);
              },
            ),
          );
        },
      );
    }

    return Column(
      children: [
        if (title.length > 1)
          InkWell(
            onTap: state ? func : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8, left: 16),
              color: state == true ? ColorTheme.lightSuccess : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (image != null)
                        SvgPicture.asset(
                          "assets/svg/IconCompleteActive.svg",
                        ),
                      if (image == null)
                        const SizedBox(
                          width: 16,
                        ),
                      const SizedBox(
                        width: 12,
                      ),
                      if (id == 1 || id == 2 || id == 3 || id == 4 || id == 5)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: CustomTextStyle.h6,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            const Text(
                              '*',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      if (id == 6 || id == 7 || id == 8 || id == 9)
                        Text(
                          title,
                          style: CustomTextStyle.h6,
                        )
                    ],
                  ),
                  if (image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.file(
                          image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (image == null)
                    const SizedBox(
                      width: 40,
                      height: 40,
                    ),
                  if (state == true && image == null)
                    Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset("assets/svg/IconCamera3.svg"))
                ],
              ),
            ),
          ),
      ],
    );
  }
}

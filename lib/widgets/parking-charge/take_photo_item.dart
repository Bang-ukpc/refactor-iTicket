import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/camera_picker.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

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
    final printIssue = Provider.of<PrintIssueProviders>(context);
    void editPhotoIssue() {
      printIssue.getIdIssue(id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CameraPicker(
            titleCamera: title,
            previewImage: true,
            editImage: true,
            onDelete: (file) {
              return true;
            },
          ),
        ),
      );
    }

    Future<void> showMyDialog() async {
      print("show dialog");
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: ColorTheme.backdrop,
        builder: (BuildContext context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: Text(title,
                            style: CustomTextStyle.h4
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.file(image!)),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                elevation: 0,
                                backgroundColor: ColorTheme.grey300,
                              ),
                              child: Text(
                                "Cancel",
                                style: CustomTextStyle.h5.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                // elevation: 0,
                                // backgroundColor: ColorTheme.grey300,
                              ),
                              child: Text(
                                "Change image",
                                style: CustomTextStyle.h5.copyWith(
                                    fontSize: 16, color: ColorTheme.white),
                              ),
                              onPressed: () {
                                Future.delayed(const Duration(seconds: 0), () {
                                  editPhotoIssue();
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        if (title.length > 1)
          InkWell(
            // tim id image null
            onTap: state
                ? func
                : image != null
                    ? showMyDialog
                    : null,
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
                              style: CustomTextStyle.h6.copyWith(fontSize: 14),
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
                          style: CustomTextStyle.h6.copyWith(fontSize: 14),
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

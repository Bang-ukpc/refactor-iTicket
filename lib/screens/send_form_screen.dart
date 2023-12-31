import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/add_image.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/custom_checkbox.dart';
import 'package:iWarden/models/send_form.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';

import '../helpers/my_navigator_observer.dart';

class SendFormScreen extends StatefulWidget {
  static const routeName = '/send-form';
  const SendFormScreen({super.key});

  @override
  BaseStatefulState<SendFormScreen> createState() => _SendFormScreenState();
}

class _SendFormScreenState extends BaseStatefulState<SendFormScreen> {
  bool checkbox = false;

  late String selectedTypeValue = listType[0].id.toString();
  late String selectedLevelValue = listLevel[0].id.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: "Send form",
        automaticallyImplyLeading: true,
      ),
      bottomNavigationBar: BottomSheet2(buttonList: [
        BottomNavyBarItem(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: SvgPicture.asset(
              "assets/svg/IconCancel2.svg",
              color: Colors.white,
            ),
            label: "Cancel"),
        BottomNavyBarItem(
            onPressed: () {},
            icon: SvgPicture.asset(
              "assets/svg/IconComplete2.svg",
            ),
            label: "Complete")
      ]),
      drawer: const MyDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: Colors.white,
              child: Column(
                children: [
                  // DropDownButtonWidget(
                  //   hintText: 'Type *',
                  //   item: listType
                  //       .map(
                  //         (itemValue) => DropdownMenuItem(
                  //           value: itemValue.id.toString(),
                  //           child: Text(
                  //             itemValue.title,
                  //             style: CustomTextStyle.h5,
                  //           ),
                  //         ),
                  //       )
                  //       .toList(),
                  //   onchanged: (value) {
                  //     setState(() {
                  //       selectedTypeValue = value as String;
                  //     });
                  //   },
                  //   value: selectedTypeValue,
                  // ),
                  const SizedBox(
                    height: 24,
                  ),
                  TextFormField(
                      style: CustomTextStyle.h6.copyWith(fontSize: 16),
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        hintText: "Please enter description",
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: ColorTheme.grey400,
                        ),
                      )),
                  const SizedBox(
                    height: 24,
                  ),
                  // if (int.parse(selectedTypeValue) != 1)
                  //   DropDownButtonWidget(
                  //     hintText: 'Level of damage *',
                  //     item: listLevel
                  //         .map(
                  //           (itemValue) => DropdownMenuItem(
                  //             value: itemValue.id.toString(),
                  //             child: Text(
                  //               itemValue.title,
                  //               style: CustomTextStyle.h5,
                  //             ),
                  //           ),
                  //         )
                  //         .toList(),
                  //     onchanged: (value) {
                  //       setState(() {
                  //         selectedLevelValue = value as String;
                  //       });
                  //     },
                  //     value: selectedLevelValue,
                  //   ),
                  if (int.parse(selectedTypeValue) != 1)
                    const SizedBox(
                      height: 24,
                    ),
                  if (int.parse(selectedTypeValue) != 1)
                    CustomCheckBox(
                      value: checkbox,
                      onChanged: (val) {
                        setState(() {
                          checkbox = val;
                        });
                      },
                      title: "Tick if a body camera was used",
                    )
                ],
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              color: Colors.white,
              child: AddImage(
                  listImage: const [],
                  onAddImage: () {},
                  displayTitle: true,
                  isCamera: true,
                  isSlideImage: false),
            )
          ],
        ),
      ),
    );
  }
}

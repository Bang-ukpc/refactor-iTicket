import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class BottomNavyBarItem extends StatelessWidget {
  final void Function()? onPressed;
  final Widget icon;
  final String label;

  const BottomNavyBarItem(
      {required this.onPressed,
      required this.icon,
      required this.label,
      super.key});

  @override
  Widget build(BuildContext context) {
    bool typeButton = label.toUpperCase().endsWith("Abort".toUpperCase());
    return Container(
      height: 40,
      child: TextButton.icon(
        style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
            backgroundColor: MaterialStateProperty.all(
                typeButton ? ColorTheme.danger : ColorTheme.primary)),
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: CustomTextStyle.h6.copyWith(color: ColorTheme.white),
        ),
      ),
    );
  }
}

class BottomSheet2 extends StatefulWidget {
  final double padding;
  final List<BottomNavyBarItem> buttonList;

  const BottomSheet2({this.padding = 5.0, required this.buttonList, super.key});

  @override
  State<BottomSheet2> createState() => _BottomSheet2State();
}

class _BottomSheet2State extends State<BottomSheet2> {
  Widget verticalLine = Container(
    height: 25,
    decoration: const BoxDecoration(
      border: Border.symmetric(
        vertical: BorderSide(
          width: 1,
          color: ColorTheme.grey300,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final widthScreen = MediaQuery.of(context).size.width;
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.buttonList.map(
          (item) {
            return (widget.buttonList.length == 1
                ? SizedBox(
                    width: widthScreen,
                    child: item,
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: ((widthScreen - widget.buttonList.length - 1) /
                            widget.buttonList.length),
                        child: item,
                      ),
                      if (item !=
                          widget.buttonList[widget.buttonList.length - 1])
                        verticalLine
                    ],
                  ));
          },
        ).toList(),
      ),
    );
  }
}

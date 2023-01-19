import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class DetailCar extends StatelessWidget {
  final String plate;
  final String? make;
  final String? color;
  final String? model;

  const DetailCar({
    required this.plate,
    required this.make,
    this.color,
    this.model,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                plate.toUpperCase(),
                style: CustomTextStyle.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              Text("Color: ${color ?? "No data"}",
                  style:
                      CustomTextStyle.h6.copyWith(color: ColorTheme.grey600)),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Make: ${make ?? "No data"}",
                style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
              ),
              Text("Model: ${model ?? "No data"}",
                  style:
                      CustomTextStyle.h6.copyWith(color: ColorTheme.grey600)),
            ],
          ),
        ],
      ),
    );
  }
}

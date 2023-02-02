import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class DetailCar extends StatelessWidget {
  final String plate;
  final String? make;
  final String? color;

  const DetailCar({
    required this.plate,
    required this.make,
    this.color,
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
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              plate.toUpperCase(),
              style: CustomTextStyle.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                style: CustomTextStyle.h5.copyWith(
                  color: ColorTheme.grey600,
                ),
              ),
              Text(
                "Color: ${color ?? "No data"}",
                style: CustomTextStyle.h5.copyWith(
                  color: ColorTheme.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

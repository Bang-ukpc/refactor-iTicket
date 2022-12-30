import 'package:flutter/material.dart';
import 'package:iWarden/common/circle.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

class CardItemParkingCharge extends StatefulWidget {
  final String? image;
  final String plate;
  final List<ContraventionReasonTranslations> contraventions;
  final DateTime created;

  const CardItemParkingCharge({
    Key? key,
    required this.image,
    required this.plate,
    required this.contraventions,
    required this.created,
  }) : super(key: key);

  @override
  State<CardItemParkingCharge> createState() => _CardItemParkingChargeState();
}

class _CardItemParkingChargeState extends State<CardItemParkingCharge> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
      ),
      elevation: 0,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: SizedBox(
              width: 72,
              height: 72,
              child: Image.network(
                "${ConfigEnvironmentVariable.azureContainerImageUrl}/${widget.image}",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/noPhoto.jpg',
                ),
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SpinKitCircle(
                      color: ColorTheme.primary,
                      size: 25,
                    ),
                  );
                },
              )),
        ),
        title: Text(
          widget.plate.toUpperCase(),
          style: CustomTextStyle.h4.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Contravention: ${widget.contraventions.map((item) => item.detail).toString().replaceAll('(', '').replaceAll(')', '')}",
              style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
            ),
            const SizedBox(height: 5),
            Text(
              "Created: ${FormatDate().getLocalDate(widget.created)}",
              style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

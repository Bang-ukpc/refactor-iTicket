import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/format_date.dart';
import 'package:iWarden/helpers/url_helper.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/parking-charge/tag_onl_off.dart';

class CardItemParkingCharge extends StatefulWidget {
  final String? image;
  final String plate;
  final List<ContraventionReasonTranslations> contraventions;
  final DateTime created;
  final bool isOffline;
  const CardItemParkingCharge({
    Key? key,
    required this.image,
    required this.plate,
    required this.contraventions,
    required this.created,
    required this.isOffline,
  }) : super(key: key);

  @override
  State<CardItemParkingCharge> createState() => _CardItemParkingChargeState();
}

class _CardItemParkingChargeState extends State<CardItemParkingCharge> {
  @override
  Widget build(BuildContext context) {
    String image = urlHelper.isLocalUrl(widget.image as String)
        ? widget.image as String
        : urlHelper.toImageUrl(widget.image as String);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: urlHelper.isHttpUrl(image)
              ? CachedNetworkImage(
                  memCacheHeight: 80,
                  memCacheWidth: 80,
                  width: 72,
                  height: 72,
                  imageUrl: image,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        color: ColorTheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/No-Image-Icon.png'),
                )
              : Image.file(
                  File(image),
                  fit: BoxFit.cover,
                  cacheWidth: 80,
                  cacheHeight: 80,
                  width: 72,
                  height: 72,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    color: ColorTheme.grey200,
                    child: Image.asset(
                      'assets/images/No-Image-Icon.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
        ),
        title: Row(
          children: [
            Text(
              widget.plate.toUpperCase(),
              style: CustomTextStyle.h4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            TagOnOff(offline: widget.isOffline),
          ],
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
              "Issued: ${FormatDate().getLocalDate(widget.created)}",
              style: CustomTextStyle.h6.copyWith(color: ColorTheme.grey600),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  ConnectivityResult checkConnection = ConnectivityResult.none;

  void checkConnectionStatus() async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    setState(() {
      checkConnection = connectionStatus;
    });
  }

  @override
  void initState() {
    checkConnectionStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: checkConnection == ConnectivityResult.wifi ||
                  checkConnection == ConnectivityResult.mobile
              ? CachedNetworkImage(
                  memCacheHeight: 80,
                  memCacheWidth: 80,
                  width: 72,
                  height: 72,
                  imageUrl:
                      "${ConfigEnvironmentVariable.azureContainerImageUrl}/${widget.image}",
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: Center(
                      child: SpinKitCircle(
                        color: ColorTheme.primary,
                        size: 25,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      Image.asset('assets/images/noPhoto.jpg'),
                )
              : Image.file(
                  File(widget.image as String),
                  fit: BoxFit.cover,
                  cacheWidth: 80,
                  cacheHeight: 80,
                  width: 72,
                  height: 72,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/images/noPhoto.jpg'),
                ),
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

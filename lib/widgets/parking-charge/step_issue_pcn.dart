import 'package:flutter/material.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:provider/provider.dart';

import '../../providers/contravention_provider.dart';

class StepIssuePCN extends StatefulWidget {
  final bool isActiveStep1;
  final void Function()? onTap1;
  final bool isActiveStep2;
  final void Function()? onTap2;
  final bool isActiveStep3;
  final void Function()? onTap3;
  const StepIssuePCN({
    required this.isActiveStep1,
    this.onTap1,
    required this.isActiveStep2,
    this.onTap2,
    required this.isActiveStep3,
    this.onTap3,
    super.key,
  });

  @override
  State<StepIssuePCN> createState() => _StepIssuePCNState();
}

class _StepIssuePCNState extends State<StepIssuePCN> {
  @override
  Widget build(BuildContext context) {
    final contraventionProvider = Provider.of<ContraventionProvider>(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: ColorTheme.white,
          child: InkWell(
            onTap: widget.onTap1,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isActiveStep1 == true
                          ? ColorTheme.primary
                          : contraventionProvider.contravention != null
                              ? ColorTheme.primary
                              : ColorTheme.grey600,
                    ),
                  ),
                  child: Material(
                    color: widget.isActiveStep1 == true
                        ? ColorTheme.primary
                        : ColorTheme.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      child: Column(
                        children: [
                          Ink(
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            width: 30,
                            height: 30,
                            child: Center(
                              child: Text(
                                "1",
                                style: CustomTextStyle.body1.copyWith(
                                  color: widget.isActiveStep1 == true
                                      ? ColorTheme.white
                                      : contraventionProvider.contravention !=
                                              null
                                          ? ColorTheme.primary
                                          : ColorTheme.grey600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  "PCN details",
                  style: CustomTextStyle.body2.copyWith(
                    color: widget.isActiveStep1 == true
                        ? ColorTheme.primary
                        : contraventionProvider.contravention != null
                            ? ColorTheme.primary
                            : ColorTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: ColorTheme.white,
          child: InkWell(
            onTap: widget.onTap2,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.isActiveStep2 == true
                            ? ColorTheme.primary
                            : contraventionProvider.contravention != null
                                ? ColorTheme.primary
                                : ColorTheme.grey600),
                  ),
                  child: Material(
                    color: widget.isActiveStep2 == true
                        ? ColorTheme.primary
                        : ColorTheme.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: widget.onTap2,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        width: 30,
                        height: 30,
                        child: Center(
                          child: Text(
                            "2",
                            style: CustomTextStyle.body1.copyWith(
                                color: widget.isActiveStep2 == true
                                    ? ColorTheme.white
                                    : contraventionProvider.contravention !=
                                            null
                                        ? ColorTheme.primary
                                        : ColorTheme.grey600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  "Take photos",
                  style: CustomTextStyle.body2.copyWith(
                      color: widget.isActiveStep2 == true
                          ? ColorTheme.primary
                          : contraventionProvider.contravention != null
                              ? ColorTheme.primary
                              : ColorTheme.grey600),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: ColorTheme.white,
          child: InkWell(
            onTap: widget.onTap3,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isActiveStep3 == true
                          ? ColorTheme.primary
                          : contraventionProvider.contravention != null
                              ? contraventionProvider.contravention!
                                      .contraventionPhotos!.isNotEmpty
                                  ? ColorTheme.primary
                                  : ColorTheme.grey600
                              : ColorTheme.grey600,
                    ),
                  ),
                  child: Material(
                    color: widget.isActiveStep3 == true
                        ? ColorTheme.primary
                        : ColorTheme.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: widget.onTap3,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        width: 30,
                        height: 30,
                        child: Center(
                          child: Text(
                            "3",
                            style: CustomTextStyle.body1.copyWith(
                              color: widget.isActiveStep3 == true
                                  ? ColorTheme.white
                                  : contraventionProvider.contravention != null
                                      ? contraventionProvider.contravention!
                                              .contraventionPhotos!.isNotEmpty
                                          ? ColorTheme.primary
                                          : ColorTheme.grey600
                                      : ColorTheme.grey600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  "Preview",
                  style: CustomTextStyle.body2.copyWith(
                    color: widget.isActiveStep3 == true
                        ? ColorTheme.primary
                        : contraventionProvider.contravention != null
                            ? contraventionProvider.contravention!
                                    .contraventionPhotos!.isNotEmpty
                                ? ColorTheme.primary
                                : ColorTheme.grey600
                            : ColorTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

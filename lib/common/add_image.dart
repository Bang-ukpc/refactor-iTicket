import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iWarden/common/my_dialog.dart';
import 'package:iWarden/screens/first-seen/add-first-seen/add_first_seen_screen.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';

// ignore: must_be_immutable
class AddImage extends StatefulWidget {
  final bool isSlideImage;
  final bool isCamera;
  List<dynamic> listImage;
  List<dynamic>? listImageFile;
  final bool? displayTitle;
  final VoidCallback onAddImage;
  final bool? imagePreview;

  AddImage({
    Key? key,
    this.isSlideImage = false,
    this.isCamera = false,
    this.displayTitle = true,
    required this.onAddImage,
    required this.listImage,
    this.listImageFile,
    this.imagePreview = false,
  }) : super(key: key);
  @override
  State<AddImage> createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  final CarouselController _controller = CarouselController();
  ConnectivityResult checkConnection = ConnectivityResult.none;

  void remove(int index) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: ColorTheme.backdrop,
      builder: (BuildContext context) {
        return MyDialog(
          title: Text(
            "Confirm",
            style: CustomTextStyle.h4.copyWith(
                color: ColorTheme.danger, fontWeight: FontWeight.w600),
          ),
          subTitle: Text(
            "Are you sure you want to delete this photo?",
            style: CustomTextStyle.h5.copyWith(fontSize: 16),
          ),
          func: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: ColorTheme.danger,
            ),
            child: Text(
              "Proceed",
              style: CustomTextStyle.h5.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              setState(() {
                widget.listImage.removeAt(index);
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

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
    print(checkConnection);
    return SingleChildScrollView(
      child: Column(
        children: [
          if (widget.isSlideImage)
            CarouselSlider(
              items: checkConnection == ConnectivityResult.wifi ||
                      checkConnection == ConnectivityResult.mobile
                  ? widget.imagePreview == false
                      ? widget.listImage.map((item) {
                          return CachedNetworkImage(
                            imageUrl: item.toString(),
                            progressIndicatorBuilder:
                                (context, url, downloadProgress) => Center(
                              child: SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  color: ColorTheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          );
                        }).toList()
                      : widget.listImageFile!.map((item) {
                          return Image.file(
                            File(item),
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          );
                        }).toList()
                  : widget.listImageFile!.map((item) {
                      return Image.file(
                        File(item),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error),
                      );
                    }).toList(),
              options: CarouselOptions(
                height: MediaQuery.of(context).size.width < 400 ? 200 : 300,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  setState(() {});
                },
                enableInfiniteScroll: false,
              ),
              carouselController: _controller,
            ),
          Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.displayTitle == true)
                    Text(
                      "Evidence photos (${widget.listImage.length})",
                      style: CustomTextStyle.h5.copyWith(
                        color: ColorTheme.darkPrimary,
                        fontSize: 16,
                      ),
                    ),
                  if (AddFirstSeenScreen.routeName ==
                      ModalRoute.of(context)!.settings.name)
                    const SizedBox(
                      height: 16,
                    ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: <Widget>[
                      if (widget.isCamera)
                        InkWell(
                          onTap: widget.onAddImage,
                          child: Container(
                            height: 56.0,
                            width: widget.listImage.isEmpty
                                ? MediaQuery.of(context).size.width - (24)
                                : 56.0,
                            margin: EdgeInsets.only(
                                right: widget.listImage.isEmpty ? 0 : 15),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: ColorTheme.grey200,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: SvgPicture.asset(
                                "assets/svg/IconCamera.svg",
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: SizedBox(
                          height: widget.isCamera ? 70.0 : 56.0,
                          child: Scrollbar(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) => Stack(
                                clipBehavior: Clip.none,
                                children: <Widget>[
                                  InkWell(
                                    onTap: () =>
                                        _controller.animateToPage(index),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          right: widget.isCamera ? 15 : 8,
                                          top: widget.isCamera ? 7 : 0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        child: SizedBox(
                                          width: 56.0,
                                          height: 56.0,
                                          child: widget.listImage[index]
                                                      .runtimeType ==
                                                  String
                                              ? checkConnection ==
                                                          ConnectivityResult
                                                              .wifi ||
                                                      checkConnection ==
                                                          ConnectivityResult
                                                              .mobile
                                                  ? widget.imagePreview == false
                                                      ? CachedNetworkImage(
                                                          imageUrl: widget
                                                              .listImage[index],
                                                          fit: BoxFit.cover,
                                                          progressIndicatorBuilder:
                                                              (context, url,
                                                                      downloadProgress) =>
                                                                  Center(
                                                                    child:
                                                                        SizedBox(
                                                                      width: 25,
                                                                      height:
                                                                          25,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        color: ColorTheme
                                                                            .primary,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error))
                                                      : Image.file(
                                                          fit: BoxFit.cover,
                                                          File(
                                                            widget.listImageFile![
                                                                index],
                                                          ),
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        )
                                                  : Image.file(
                                                      fit: BoxFit.cover,
                                                      File(
                                                        widget.listImageFile![
                                                            index],
                                                      ),
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Icons.error),
                                                    )
                                              : Image.file(
                                                  widget.listImage[index],
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (widget.isCamera)
                                    Positioned(
                                      top: 0,
                                      right: 5,
                                      child: InkWell(
                                        onTap: () {
                                          remove(index);
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            color: ColorTheme.grey400,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: SvgPicture.asset(
                                            "assets/svg/IconCannel.svg",
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              itemCount: widget.listImage.length,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

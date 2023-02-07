library camera_picker;

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/Camera/picker_store.dart';
import 'package:iWarden/common/IconButtonCamera/build_icon.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/app_bar.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

const _defaultPreviewHeight = 60.0;
const _defaultPreviewWidth = 80.0;

class CameraPicker extends HookWidget {
  final Function(dynamic error, dynamic stack)? onError;

  final ResolutionPreset resolutionPreset;

  final int? maxPicture;

  final int minPicture;

  final bool showCancelButton;

  final bool showTorchButton;

  final bool showSwitchCameraButton;

  final Color iconColor;

  final double previewHeight;

  final double previewWidth;

  final FutureOr<bool> Function(File file)? onDelete;

  final List<File>? initialFiles;

  final int? typePCN;

  final WidgetBuilder? noCameraBuilder;
  final String titleCamera;
  final bool? previewImage;
  final bool front;
  final bool editImage;
  final bool? isDisplayFunctionKey;

  const CameraPicker({
    Key? key,
    this.initialFiles,
    this.previewHeight = _defaultPreviewHeight,
    this.previewWidth = _defaultPreviewWidth,
    this.noCameraBuilder,
    this.showSwitchCameraButton = true,
    this.onDelete,
    this.resolutionPreset = ResolutionPreset.high,
    this.iconColor = Colors.white,
    this.showTorchButton = true,
    this.showCancelButton = true,
    this.onError,
    this.maxPicture,
    this.minPicture = 1,
    this.front = false,
    this.previewImage = false,
    this.editImage = false,
    required this.titleCamera,
    this.typePCN,
    this.isDisplayFunctionKey = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = useMemoized(() => PickerStore(
        filesData: List.from(initialFiles ?? []),
        minPicture: minPicture,
        maxPicture: maxPicture));
    var filesDataImage = useState<int>(store.filesData.length);
    var cameraOn = useState<bool>(true);
    final availableCamerasFuture = useMemoized(() => availableCameras());
    final cameras = useState<List<CameraDescription>?>(null);
    final printIssue = Provider.of<PrintIssueProviders>(context);
    final widthScreen = MediaQuery.of(context).size.width;
    const padding = 30.0;

    final appLifecycleState = useAppLifecycleState();

    Future<bool> checkCameraPermission() async {
      return await Permission.camera.isGranted;
    }

    Future<void> showDiaLog(double widthScreen, double padding,
        BuildContext context, File img) async {
      showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          barrierColor: Colors.black45,
          transitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (BuildContext buildContext, Animation animation,
              Animation secondaryAnimation) {
            return Scaffold(
                appBar: MyAppBar(
                  title: printIssue.findIssueNoImage(typePCN: typePCN).title,
                  automaticallyImplyLeading: true,
                  isOpenDrawer: false,
                ),
                bottomNavigationBar: BottomSheet2(buttonList: [
                  BottomNavyBarItem(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: SvgPicture.asset(
                        'assets/svg/IconDelete.svg',
                        color: Colors.white,
                      ),
                      label: 'Delete'),
                  BottomNavyBarItem(
                    onPressed: () async {
                      if (printIssue.findIssueNoImage(typePCN: typePCN).id !=
                          printIssue.data.length) {
                        if (!editImage) {
                          await printIssue.getIdIssue(
                              printIssue.findIssueNoImage(typePCN: typePCN).id);
                          printIssue.addImageToIssue(printIssue.idIssue, img);
                          Navigator.of(context).pop();
                        } else {
                          printIssue.addImageToIssue(printIssue.idIssue, img);
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }
                      } else {
                        await printIssue.getIdIssue(
                            printIssue.findIssueNoImage(typePCN: typePCN).id);
                        printIssue.addImageToIssue(printIssue.idIssue, img);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    },
                    icon: SvgPicture.asset(
                      'assets/svg/IconComplete.svg',
                      color: Colors.white,
                    ),
                    label: 'Accept',
                  ),
                ]),
                body: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 55),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.white,
                            child: Text(
                              "Please Accept or Delete the Photo",
                              style: CustomTextStyle.h5
                                  .copyWith(color: ColorTheme.grey600),
                            ),
                          ),
                          Image.file(
                            img,
                            fit: BoxFit.cover,
                          ),
                        ]),
                  ),
                ));
          }).then((value) {
        // if (isCamera == false) {
        //   SystemChrome.setPreferredOrientations([
        //     DeviceOrientation.portraitUp,
        //     DeviceOrientation.portraitDown,
        //     DeviceOrientation.landscapeLeft,
        //     DeviceOrientation.landscapeRight
        //   ]);
        // } else {
        //   SystemChrome.setPreferredOrientations([
        //     DeviceOrientation.portraitUp,
        //     DeviceOrientation.portraitDown,
        //   ]);
        // }
      });
    }

    var isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    void actionCamera(CameraController cameraController) async {
      try {
        final file = await cameraController.takePicture();
        var imageFile = File(file.path);
        final tempDir = await syspaths.getTemporaryDirectory();
        final fileName = path.basename(file.path);
        File files = await File('${tempDir.path}/$fileName').create();
        var capturedImage = img.decodeImage(await file.readAsBytes());
        img.encodeJpg(capturedImage!, quality: 40);
        store.addFile(files);
        filesDataImage.value = filesDataImage.value + 1;
        previewImage == true
            // ignore: use_build_context_synchronously
            ? showDiaLog(widthScreen, padding, context, files)
            : null;
      } catch (ex, stack) {
        onError?.call(ex, stack);
      }

      // try {
      //   final file = await cameraController.takePicture();
      //   final tempDir = await syspaths.getTemporaryDirectory();

      //   var imageFile = File(file.path);

      //   final targetPath = '${tempDir.absolute.path}/temp.jpg';

      //   var result = await FlutterImageCompress.compressAndGetFile(
      //     imageFile.absolute.path,
      //     targetPath,
      //     quality: isReduceSizeImage == true ? 10 : 95,
      //   );

      //   log('file original: ${imageFile.lengthSync().toString()}');
      //   log('file compress: ${result!.lengthSync().toString()}');

      //   final fileName = path.basename(result.path);
      //   File files = await File('${tempDir.path}/$fileName').create();
      //   // var capturedImage = img.decodeImage(await file.readAsBytes());
      //   // final img.Image orientedImage = img.bakeOrientation(capturedImage!);

      //   store.addFile(files);
      //   filesDataImage.value = filesDataImage.value + 1;
      //   previewImage == true
      //       // ignore: use_build_context_synchronously
      //       ? showDiaLog(widthScreen, padding, context, files)
      //       : null;
      // } catch (ex, stack) {
      //   onError?.call(ex, stack);
      // }
    }

    return Material(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ColoredBox(
          color: Colors.black,
          child: FutureBuilder<List<CameraDescription>>(
            builder: (context, snapshot) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (snapshot.connectionState == ConnectionState.done) {
                  cameras.value ??= snapshot.data ?? [];
                }
              });

              if (snapshot.connectionState == ConnectionState.waiting ||
                  cameras.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (cameras.value!.isEmpty) {
                return noCameraBuilder?.call(context) ??
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No camera available',
                            style:
                                TextStyle(color: Theme.of(context).errorColor),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Back'))
                        ],
                      ),
                    );
              }

              return HookBuilder(builder: (context) {
                final cameraControllerState = useState(CameraController(
                  cameras.value!.firstWhereOrNull((element) =>
                          element.lensDirection ==
                          (front
                              ? CameraLensDirection.front
                              : CameraLensDirection.back)) ??
                      cameras.value!.first,
                  resolutionPreset,
                  enableAudio: false,
                ));

                final cameraController = cameraControllerState.value;
                final initializeCamera = useMemoized(
                    () => cameraController.initialize(), [cameraController]);

                useEffect(() {
                  checkCameraPermission().then((value) {
                    if (value == true) {
                      if (appLifecycleState == AppLifecycleState.paused ||
                          appLifecycleState == AppLifecycleState.inactive) {
                        cameraController.dispose();
                        cameraOn.value = false;
                      } else if (appLifecycleState ==
                          AppLifecycleState.resumed) {
                        if (cameraOn.value == false) {
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  });
                  return null;
                }, [appLifecycleState]);

                return WillPopScope(
                  onWillPop: () async {
                    cameraController.dispose();
                    // SystemChrome.setPreferredOrientations([
                    //   DeviceOrientation.portraitUp,
                    //   DeviceOrientation.portraitDown,
                    //   DeviceOrientation.landscapeLeft,
                    //   DeviceOrientation.landscapeRight
                    // ]);
                    return true;
                  },
                  child: FutureBuilder(
                      future: initializeCamera,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var camera = cameraController.value;
                        final size = MediaQuery.of(context).size;
                        var scale = size.aspectRatio * camera.aspectRatio;
                        if (scale < 1) scale = 1 / scale;

                        return CameraPreview(
                          cameraController,
                          key: Key(cameraController.description.name),
                          child: SafeArea(
                            top: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 36,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              color: ColorTheme.backdrop2,
                                              padding: const EdgeInsets.only(
                                                left: 0,
                                                right: 15,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        icon: SvgPicture.asset(
                                                          "assets/svg/IconBack.svg",
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Text(
                                                        !editImage
                                                            ? printIssue
                                                                .findIssueNoImage(
                                                                    typePCN:
                                                                        typePCN)
                                                                .title
                                                            : titleCamera,
                                                        style: CustomTextStyle
                                                            .h5
                                                            .copyWith(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16),
                                                      ),
                                                    ],
                                                  ),
                                                  HookBuilder(
                                                      builder: (context) {
                                                    final mode = useState(
                                                        FlashMode.auto);
                                                    return InkWell(
                                                      onTap: () {
                                                        if (mode.value ==
                                                            FlashMode.auto) {
                                                          mode.value =
                                                              FlashMode.torch;
                                                          cameraController
                                                              .setFlashMode(
                                                                  FlashMode
                                                                      .torch);
                                                        } else {
                                                          mode.value =
                                                              FlashMode.auto;
                                                          cameraController
                                                              .setFlashMode(
                                                                  FlashMode
                                                                      .auto);
                                                        }
                                                      },
                                                      child: SvgPicture.asset(
                                                        mode.value ==
                                                                FlashMode.auto
                                                            ? "assets/svg/OffFlash.svg"
                                                            : "assets/svg/OnFlash.svg",
                                                      ),
                                                    );
                                                  })
                                                ],
                                              ),
                                            ),
                                            if (isLandscape)
                                              if (previewImage == false)
                                                HookBuilder(builder: (context) {
                                                  useListenable(store);
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: ImagesPreview(
                                                      files: store.filesData,
                                                      iconColor: iconColor,
                                                      borderColor: iconColor,
                                                      previewWidth:
                                                          previewWidth,
                                                      previewHeight:
                                                          previewHeight,
                                                      onDelete: (index) async {
                                                        if (onDelete == null ||
                                                            await onDelete!(
                                                                store.filesData[
                                                                    index])) {
                                                          store.removeFile(
                                                              store.filesData[
                                                                  index]);
                                                          filesDataImage.value =
                                                              filesDataImage
                                                                      .value -
                                                                  1;
                                                        }
                                                      },
                                                    ),
                                                  );
                                                }),
                                            // const SizedBox(
                                            //   height: 5,
                                            // )
                                          ],
                                        ),
                                      ),
                                      if (isLandscape)
                                        // if (previewImage == false)
                                        Container(
                                          color: ColorTheme.backdrop2,
                                          child: Row(
                                            children: [
                                              // Column(
                                              //   children: [
                                              //     Container(
                                              //       width: 70,
                                              //       height: 70,
                                              //       color: ColorTheme.danger,
                                              //     )
                                              //   ],
                                              // ),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 10.9,
                                                        vertical: 55),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        filesDataImage.value > 0
                                                            ? isDisplayFunctionKey ==
                                                                    true
                                                                ? InkWell(
                                                                    onTap: () {
                                                                      cameraController
                                                                          .dispose();
                                                                      // SystemChrome
                                                                      //     .setPreferredOrientations([
                                                                      //   DeviceOrientation
                                                                      //       .portraitUp,
                                                                      //   DeviceOrientation
                                                                      //       .portraitDown,
                                                                      //   DeviceOrientation
                                                                      //       .landscapeLeft,
                                                                      //   DeviceOrientation
                                                                      //       .landscapeRight
                                                                      // ]);
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child:
                                                                        const BuildIcon(
                                                                      width: 34,
                                                                      height:
                                                                          34,
                                                                      assetIcon:
                                                                          "assets/svg/IconCloseCamera.svg",
                                                                    ),
                                                                  )
                                                                : const SizedBox()
                                                            : const SizedBox(),
                                                        InkWell(
                                                          onTap: () {
                                                            actionCamera(
                                                                cameraController);
                                                          },
                                                          child:
                                                              const BuildIcon(
                                                            width: 68,
                                                            height: 68,
                                                            color:
                                                                Color.fromRGBO(
                                                                    255,
                                                                    255,
                                                                    255,
                                                                    0.2),
                                                            assetIcon:
                                                                "assets/svg/IconCamera2.svg",
                                                          ),
                                                        ),
                                                        filesDataImage.value > 0
                                                            ? isDisplayFunctionKey ==
                                                                    true
                                                                ? HookBuilder(
                                                                    builder:
                                                                        (context) {
                                                                      useListenable(
                                                                          store);

                                                                      return InkWell(
                                                                        onTap: store.canContinue
                                                                            ? () {
                                                                                cameraController.dispose();
                                                                                Navigator.of(context).pop(store.filesData);
                                                                                // SystemChrome.setPreferredOrientations([
                                                                                //   DeviceOrientation.portraitUp,
                                                                                //   DeviceOrientation.portraitDown,
                                                                                //   DeviceOrientation.landscapeLeft,
                                                                                //   DeviceOrientation.landscapeRight
                                                                                // ]);
                                                                              }
                                                                            : null,
                                                                        enableFeedback:
                                                                            true,
                                                                        child:
                                                                            const BuildIcon(
                                                                          width:
                                                                              34,
                                                                          height:
                                                                              34,
                                                                          assetIcon:
                                                                              "assets/svg/IconCom.svg",
                                                                        ),
                                                                      );
                                                                    },
                                                                  )
                                                                : const SizedBox()
                                                            : const SizedBox(),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!isLandscape)
                                  if (previewImage == false)
                                    HookBuilder(builder: (context) {
                                      useListenable(store);
                                      return ImagesPreview(
                                        files: store.filesData,
                                        iconColor: iconColor,
                                        borderColor: iconColor,
                                        previewWidth: previewWidth,
                                        previewHeight: previewHeight,
                                        onDelete: (index) async {
                                          if (onDelete == null ||
                                              await onDelete!(
                                                  store.filesData[index])) {
                                            store.removeFile(
                                                store.filesData[index]);
                                            filesDataImage.value =
                                                filesDataImage.value - 1;
                                          }
                                        },
                                      );
                                    }),
                                if (!isLandscape)
                                  Container(
                                    color: ColorTheme.backdrop2,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 60, vertical: 50),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        filesDataImage.value > 0
                                            ? isDisplayFunctionKey == true
                                                ? InkWell(
                                                    onTap: () {
                                                      cameraController
                                                          .dispose();
                                                      // SystemChrome
                                                      //     .setPreferredOrientations([
                                                      //   DeviceOrientation
                                                      //       .portraitUp,
                                                      //   DeviceOrientation
                                                      //       .portraitDown,
                                                      //   DeviceOrientation
                                                      //       .landscapeLeft,
                                                      //   DeviceOrientation
                                                      //       .landscapeRight
                                                      // ]);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const BuildIcon(
                                                      width: 34,
                                                      height: 34,
                                                      assetIcon:
                                                          "assets/svg/IconCloseCamera.svg",
                                                    ),
                                                  )
                                                : const SizedBox()
                                            : const SizedBox(),
                                        InkWell(
                                          onTap: () async {
                                            actionCamera(cameraController);
                                          },
                                          child: const BuildIcon(
                                            width: 68,
                                            height: 68,
                                            color: Color.fromRGBO(
                                                255, 255, 255, 0.2),
                                            assetIcon:
                                                "assets/svg/IconCamera2.svg",
                                          ),
                                        ),
                                        filesDataImage.value > 0
                                            ? isDisplayFunctionKey == true
                                                ? HookBuilder(
                                                    builder: (context) {
                                                    useListenable(store);

                                                    return InkWell(
                                                      onTap: store.canContinue
                                                          ? () {
                                                              cameraController
                                                                  .dispose();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(store
                                                                      .filesData);
                                                              // SystemChrome
                                                              //     .setPreferredOrientations([
                                                              //   DeviceOrientation
                                                              //       .portraitUp,
                                                              //   DeviceOrientation
                                                              //       .portraitDown,
                                                              //   DeviceOrientation
                                                              //       .landscapeLeft,
                                                              //   DeviceOrientation
                                                              //       .landscapeRight
                                                              // ]);
                                                            }
                                                          : null,
                                                      enableFeedback: true,
                                                      child: const BuildIcon(
                                                        width: 34,
                                                        height: 34,
                                                        assetIcon:
                                                            "assets/svg/IconCom.svg",
                                                      ),
                                                    );
                                                  })
                                                : const SizedBox()
                                            : const SizedBox(),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                        );
                      }),
                );
              });
            },
            future: availableCamerasFuture,
          ),
        ),
      ),
    );
  }
}

/// ImagesPreview is a widget to show preview of files with
class ImagesPreview extends HookWidget {
  /// Files to show in preview
  final List<File> files;

  /// Callback when delete button is pressed, but don't delete the file, that's on you to so it and update [files]
  final Function(int index)? onDelete;

  /// Height of the preview, default to 60
  final double previewHeight;

  /// Widget of the preview, default to 80
  final double previewWidth;

  /// Icon color
  final Color iconColor;

  /// Border color
  final Color borderColor;

  const ImagesPreview({
    Key? key,
    this.previewHeight = _defaultPreviewHeight,
    this.previewWidth = _defaultPreviewWidth,
    this.iconColor = Colors.white,
    this.borderColor = Colors.white,
    this.onDelete,
    required this.files,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ioFiles = useMemoized(
        () => files.map((e) => File(e.path)).toList(), [files, files.length]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 21),
        child: Row(
          children: [
            for (var i = 0; i < ioFiles.length; i++)
              ImagePreview(
                file: ioFiles[i],
                previewHeight: previewHeight,
                previewWidth: previewWidth,
                borderColor: borderColor,
                iconColor: iconColor,
                onDelete: onDelete == null
                    ? null
                    : () {
                        onDelete?.call(i);
                      },
              ),
          ],
        ),
      ),
    );
  }
}

/// Preview on one single image use in [ImagePreviews]
class ImagePreview extends StatelessWidget {
  // File to preview
  final File file;

  /// Border color of the preview
  final Color borderColor;

  /// Icon color of the preview
  final Color iconColor;

  /// Delete button pressed callback, delegate the actual deletion to you
  final VoidCallback? onDelete;

  /// Height of the preview, default to 60
  final double previewHeight;

  /// Widget of the preview, default to 80
  final double previewWidth;

  const ImagePreview(
      {Key? key,
      this.previewHeight = 60,
      this.previewWidth = 80,
      this.onDelete,
      required this.file,
      this.iconColor = Colors.white,
      this.borderColor = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight / 1.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: borderColor)),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Stack(
                  children: [
                    Image.file(
                      file,
                      height: previewHeight,
                      width: previewWidth,
                      fit: BoxFit.cover,
                    ),
                    if (onDelete != null)
                      Positioned(
                        top: -10,
                        right: -10,
                        child: IconButton(
                          onPressed: onDelete,
                          color: iconColor,
                          iconSize: 18,
                          tooltip: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          icon: const Icon(Icons.cancel),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

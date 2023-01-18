import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/configs/const.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/controllers/abort_controller.dart';
import 'package:iWarden/controllers/user_controller.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AbortScreen extends StatefulWidget {
  static const routeName = '/abort';
  const AbortScreen({super.key});

  @override
  State<AbortScreen> createState() => _AbortScreenState();
}

class _AbortScreenState extends State<AbortScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<CancellationReason> cancellationReasonList = [];
  final TextEditingController _cancellationReasonController =
      TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = true;

  void getCancellationReasonList() async {
    await abortController.getCancellationReasonList().then((value) {
      setState(() {
        isLoading = false;
        cancellationReasonList = value;
      });
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getCancellationReasonList();
  }

  @override
  void dispose() {
    _cancellationReasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Contravention;
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    final printIssue = Provider.of<PrintIssueProviders>(context);

    Future<void> abortPCN() async {
      final wardenEventAbortPCN = WardenEvent(
        type: TypeWardenEvent.AbortPCN.index,
        detail: 'Abort PCN: ${args.reference}',
        latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        wardenId: wardensProvider.wardens?.Id ?? 0,
        zoneId: locationProvider.zone?.Id ?? 0,
        locationId: locationProvider.location?.Id ?? 0,
        rotaTimeFrom: locationProvider.rotaShift?.timeFrom,
        rotaTimeTo: locationProvider.rotaShift?.timeTo,
      );

      final abortPcnBody = AbortPCN(
        contraventionId: args.id as int,
        cancellationReasonId: _cancellationReasonController.text != ''
            ? int.tryParse(_cancellationReasonController.text) as int
            : 0,
        comment: _commentController.text,
      );
      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      }

      try {
        await abortController.abortPCN(abortPcnBody).then((value) async {
          await userController
              .createWardenEvent(wardenEventAbortPCN)
              .then((value) {
            Navigator.of(context).pushNamed(ParkingChargeList.routeName);
          });
        });
      } on DioError catch (error) {
        if (!mounted) return;
        if (error.type == DioErrorType.other) {
          CherryToast.error(
            toastDuration: const Duration(seconds: 3),
            title: Text(
              error.message.length > Constant.errorTypeOther
                  ? 'Something went wrong, please try again'
                  : error.message,
              style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
            ),
            toastPosition: Position.bottom,
            borderRadius: 5,
          ).show(context);
          return;
        }
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length >
                    Constant.errorMaxLength
                ? 'Internal server error'
                : error.response!.data['message'],
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }
      printIssue.resetData();
      _formKey.currentState!.save();
      return;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          drawer: const MyDrawer(),
          bottomNavigationBar: BottomSheet2(buttonList: [
            BottomNavyBarItem(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: SvgPicture.asset('assets/svg/IconCancel2.svg'),
              label: const Text(
                'Cancel',
                style: CustomTextStyle.h6,
              ),
            ),
            BottomNavyBarItem(
              onPressed: () {
                abortPCN();
              },
              icon: SvgPicture.asset('assets/svg/IconComplete2.svg'),
              label: const Text(
                'Finish abort',
                style: CustomTextStyle.h6,
              ),
            ),
          ]),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: ColorTheme.danger,
                  padding: const EdgeInsets.all(10),
                  child: Center(
                      child: Text(
                    "Abort PCN",
                    style: CustomTextStyle.h4.copyWith(color: Colors.white),
                  )),
                ),
                Container(
                  color: ColorTheme.white,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please select the reasons and submit to abort this parking charge.',
                          style: CustomTextStyle.body1.copyWith(
                            color: ColorTheme.grey600,
                          ),
                        ),
                        isLoading == false
                            ? Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    SizedBox(
                                      child: DropdownSearch<CancellationReason>(
                                        dropdownDecoratorProps:
                                            DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              dropDownButtonStyle
                                                  .getInputDecorationCustom(
                                            labelText: const LabelRequire(
                                              labelText: 'Reason',
                                            ),
                                            hintText: 'Select reason',
                                          ),
                                        ),
                                        items: cancellationReasonList,
                                        itemAsString: (item) => item.reason,
                                        popupProps: PopupProps.menu(
                                          fit: FlexFit.loose,
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          itemBuilder:
                                              (context, item, isSelected) =>
                                                  DropDownItem(
                                            isSelected: item.Id.toString() ==
                                                _cancellationReasonController
                                                    .text,
                                            title: item.reason,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _cancellationReasonController.text =
                                                value!.Id.toString();
                                          });
                                        },
                                        validator: ((value) {
                                          if (value == null) {
                                            return 'Please select reason';
                                          }
                                          return null;
                                        }),
                                        autoValidateMode:
                                            AutovalidateMode.onUserInteraction,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    TextFormField(
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[^\s]+\b\s?'),
                                        ),
                                      ],
                                      style: CustomTextStyle.h5,
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter comment',
                                        label: Text(
                                          "Comment",
                                        ),
                                        hintMaxLines: 1,
                                      ),
                                      maxLines: 3,
                                      onSaved: (value) {
                                        _commentController.text =
                                            value as String;
                                      },
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                  ],
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.only(
                                  top: 20,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

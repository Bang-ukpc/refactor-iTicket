import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/show_loading.dart';
import 'package:iWarden/configs/current_location.dart';
import 'package:iWarden/helpers/user_info.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/providers/contravention_provider.dart';
import 'package:iWarden/providers/locations.dart';
import 'package:iWarden/providers/print_issue_providers.dart';
import 'package:iWarden/providers/wardens_info.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/pcn_information/parking_charge_list.dart';
import 'package:iWarden/services/cache/factory/cache_factory.dart';
import 'package:iWarden/services/local/created_warden_event_local_service%20.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:provider/provider.dart';

import '../../helpers/my_navigator_observer.dart';

class AbortScreen extends StatefulWidget {
  static const routeName = '/abort';
  const AbortScreen({super.key});

  @override
  BaseStatefulState<AbortScreen> createState() => _AbortScreenState();
}

class _AbortScreenState extends BaseStatefulState<AbortScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<CancellationReason> cancellationReasons = [];
  final TextEditingController _cancellationReasonController =
      TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = true;
  final CachedServiceFactory cachedServiceFactory =
      CachedServiceFactory(userInfo.user?.Id ?? 0);

  Future<void> getCancellationReasons() async {
    await cachedServiceFactory.cancellationReasonCachedService
        .getAll()
        .then((value) {
      setState(() {
        isLoading = false;
        cancellationReasons = value;
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
    getCancellationReasons();
  }

  @override
  void dispose() {
    _cancellationReasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<Locations>(context);
    final wardensProvider = Provider.of<WardensInfo>(context);
    final printIssue = Provider.of<PrintIssueProviders>(context);
    final contraventionProvider = Provider.of<ContraventionProvider>(context);

    Future<void> abortPCN() async {
      final wardenEventAbortPCN = WardenEvent(
        type: TypeWardenEvent.AbortPCN.index,
        detail:
            'Abort PCN, comment: ${_commentController.text.isNotEmpty ? _commentController.text : "no comment"}',
        latitude: currentLocationPosition.currentLocation?.latitude ?? 0,
        longitude: currentLocationPosition.currentLocation?.longitude ?? 0,
        wardenId: wardensProvider.wardens?.Id ?? 0,
        zoneId: locationProvider.zone?.Id ?? 0,
        locationId: locationProvider.location?.Id ?? 0,
        rotaTimeFrom: locationProvider.rotaShift?.timeFrom,
        rotaTimeTo: locationProvider.rotaShift?.timeTo,
        cancellationReasonId:
            int.tryParse(_cancellationReasonController.text) ?? 0,
      );
      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      }

      showCircularProgressIndicator(context: context);
      await createdWardenEventLocalService
          .create(wardenEventAbortPCN)
          .then((value) {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(ParkingChargeList.routeName);
      });

      contraventionProvider.clearContraventionData();
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
              icon: SvgPicture.asset(
                'assets/svg/IconCancel2.svg',
                color: ColorTheme.textPrimary,
              ),
              label: 'Cancel',
            ),
            BottomNavyBarItem(
              onPressed: () {
                abortPCN();
              },
              icon: SvgPicture.asset(
                'assets/svg/IconAbort2.svg',
              ),
              label: 'Finish abort',
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
                  margin: const EdgeInsets.only(top: 8),
                  height: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please select the reasons and submit to abort this parking charge.',
                          style: CustomTextStyle.body1.copyWith(
                            color: ColorTheme.grey600,
                            fontSize: 16,
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
                                        dropdownBuilder:
                                            (context, selectedItem) {
                                          return Text(
                                              selectedItem == null
                                                  ? "Select vehicle reason"
                                                  : selectedItem.reason,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: selectedItem == null
                                                      ? ColorTheme.grey400
                                                      : ColorTheme
                                                          .textPrimary));
                                        },
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
                                        items: cancellationReasons,
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
                                      height: 20,
                                    ),
                                    TextFormField(
                                      style: CustomTextStyle.h5
                                          .copyWith(fontSize: 16),
                                      controller: _commentController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter comment',
                                        label: Text(
                                          "Comment",
                                        ),
                                        hintMaxLines: 1,
                                        hintStyle: TextStyle(
                                          fontSize: 16,
                                          color: ColorTheme.grey400,
                                        ),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.only(
                                  top: 30,
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

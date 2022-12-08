import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iWarden/common/bottom_sheet_2.dart';
import 'package:iWarden/common/drop_down_button_style.dart';
import 'package:iWarden/common/label_require.dart';
import 'package:iWarden/common/toast.dart';
import 'package:iWarden/controllers/abort_controller.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/screens/location/location_screen.dart';
import 'package:iWarden/screens/parking-charges/parking_charge_list.dart';
import 'package:iWarden/theme/color.dart';
import 'package:iWarden/theme/text_theme.dart';
import 'package:iWarden/widgets/drawer/app_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Abort {
  final String id;
  final String reason;
  Abort({required this.id, required this.reason});
}

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

  void getCancellationReasonList() async {
    await abortController.getCancellationReasonList().then((value) {
      setState(() {
        cancellationReasonList = value;
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
    final heightScreen = MediaQuery.of(context).size.height;
    final args = ModalRoute.of(context)!.settings.arguments as Contravention;

    AbortPCN abortPcnBody = AbortPCN(
      contraventionId: args.id as int,
      cancellationReasonId: _cancellationReasonController.text != ''
          ? int.tryParse(_cancellationReasonController.text) as int
          : 0,
      comment: _commentController.text,
    );

    Future<void> abortPCN() async {
      final isValid = _formKey.currentState!.validate();

      if (!isValid) {
        return;
      }

      try {
        await abortController.abortPCN(abortPcnBody).then((value) {
          Navigator.of(context).pushNamed(ParkingChargeList.routeName);
        });
      } on DioError catch (error) {
        CherryToast.error(
          displayCloseButton: false,
          title: Text(
            error.response!.data['message'].toString().length > 30
                ? 'Something went wrong'
                : error.response!.data['message'],
            style: CustomTextStyle.h5.copyWith(color: ColorTheme.danger),
          ),
          toastPosition: Position.bottom,
          borderRadius: 5,
        ).show(context);
      }

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
          bottomSheet: BottomSheet2(buttonList: [
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
                  padding: const EdgeInsets.all(8),
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
                  height: heightScreen / 2.3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please select the reasons and submit to abort this parking charge.',
                            style: CustomTextStyle.body1.copyWith(
                              color: ColorTheme.grey600,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          SizedBox(
                            child: DropdownSearch<CancellationReason>(
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: dropDownButtonStyle
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
                                itemBuilder: (context, item, isSelected) =>
                                    DropDownItem(
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
                              _commentController.text = value as String;
                            },
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                        ],
                      ),
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

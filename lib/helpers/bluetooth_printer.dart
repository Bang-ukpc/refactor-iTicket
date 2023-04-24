import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:iWarden/helpers/time_helper.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/location.dart';
import 'package:intl/intl.dart';

import '../providers/time_ntp.dart';

class BluetoothPrinterHelper {
  var isBle = false;
  var isConnected = false;
  var printerManager = PrinterManager.instance;
  var devices = <BluetoothPrinter>[];
  StreamSubscription<PrinterDevice>? subscription;
  StreamSubscription<BTStatus>? subscriptionBtStatus;
  BTStatus currentStatus = BTStatus.none;
  List<int> pendingTask = [];
  BluetoothPrinter? selectedPrinter;

  void scan() {
    devices.clear();
    subscription = printerManager
        .discovery(type: PrinterType.bluetooth, isBle: isBle)
        .listen(
      (device) {
        devices.add(BluetoothPrinter(
          deviceName: device.name,
          address: device.address,
          isBle: isBle,
          vendorId: device.vendorId,
          productId: device.productId,
          typePrinter: PrinterType.bluetooth,
        ));
        if (devices.isNotEmpty) {
          BluetoothPrinter? deviceSelected = devices.firstWhereOrNull(
              (device) => device.deviceName!
                  .toUpperCase()
                  .contains('ezpcn'.toUpperCase()));
          if (deviceSelected != null) {
            selectDevice(deviceSelected);
          }
        }
      },
    );
  }

  void initConnect() {
    subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen(
      (status) {
        log(' ----------------- status bt $status ------------------ ');
        currentStatus = status;
        if (status == BTStatus.connected) {
          isConnected = true;
        }
        if (status == BTStatus.none) {
          isConnected = false;
        }
        if (status == BTStatus.connected && pendingTask.isNotEmpty) {
          if (Platform.isAndroid) {
            Future.delayed(const Duration(milliseconds: 1000), () async {
              var result = await PrinterManager.instance
                  .send(type: PrinterType.bluetooth, bytes: pendingTask);
              log(result.toString());
              pendingTask = [];
            });
          } else if (Platform.isIOS) {
            PrinterManager.instance
                .send(type: PrinterType.bluetooth, bytes: pendingTask);
            pendingTask = [];
          }
        }
      },
    );
  }

  Future<void> selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance
            .disconnect(type: selectedPrinter!.typePrinter);
      }
    }

    selectedPrinter = device;
    log('Select device');
  }

  Future<void> connectToPrinter() async {
    if (selectedPrinter == null) return;
    var bluetoothPrinter = selectedPrinter!;
    log("_printEscPos: ${bluetoothPrinter.typePrinter.toString()}");
    await printerManager
        .connect(
          type: bluetoothPrinter.typePrinter,
          model: BluetoothPrinterInput(
            name: bluetoothPrinter.deviceName,
            address: bluetoothPrinter.address!,
            isBle: bluetoothPrinter.isBle ?? false,
            autoConnect: false,
          ),
        )
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => false,
        );
  }

  Future printReceiveTest() async {
    String fontStyle1 = "^A1N,24,12";
    String fontStyle2 = "^A1N,14,12";
    DateTime now = await timeNTP.getTimeWithUKTime();
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 145;
    int referenceNo = 78;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 65;
    int location = color + 50;
    int issueTime = location + 165;
    int timeFirstSeen = issueTime + 60;
    int desc = timeFirstSeen + 200;
    int referenceNo2 = desc + 535;
    int date2 = referenceNo2 + 60;
    int plate2 = date2 + 60;
    int barcode = plate2 + 70;
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.text(
        '! U1 setvar "media.type" "label" ! U1 setvar "media.sense_mode" "bar" ! U1 setvar "device.languages" "zpl" ! U1 setvar "device.pnp_option" "zpl" ^XA^POI^FO$xAxis,$referenceNo$fontStyle1^FD1234567890123^FS^FO$xAxis,$date^A,$fontStyle1^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis,$plate$fontStyle1^FDXX99XXX^FS^FO$xAxis,$make$fontStyle1^FDMAKE^FS^FO$xAxis,$color$fontStyle1^FDCOLOUR^FS^FO$xAxis,$location$fontStyle2^FDVOID A2^FS^FO$xAxis,${location + 40}$fontStyle2^FDVOID A3^FS^FO$xAxis,${location + 80}$fontStyle2^FDVOID A4^FS^FO$xAxis,${location + 120}$fontStyle2^FDVOID A5^FS^FO$xAxis,$issueTime$fontStyle1^FD${DateFormat('HH:mm dd-MM-yyyy').format(now)}^FS^FO$xAxis,$timeFirstSeen$fontStyle1^FD${DateFormat('HH:mm dd-MM-yyyy').format(now)}^FS^FO$xAxis2,$desc$fontStyle2^FDVOID 02^FS^FO$xAxis2,${desc + 20}$fontStyle2^FDVOID 03^FS^FO$xAxis2,${desc + 40}$fontStyle2^FDVOID 04^FS^FO$xAxis3,$referenceNo2$fontStyle1^FD1234567890123^FS^FO$xAxis3,$date2$fontStyle1^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis3,$plate2$fontStyle1^FDXX99XXX^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD1234567890123^FS^XZ');

    await printEscPos(bytes, generator);
  }

  bool isTextNull(String? text) {
    return text == null || text.isEmpty;
  }

  // Future printPhysicalPCN(
  //     {required Contravention physicalPCN,
  //     required Location locationName,
  //     required double lowerAmount,
  //     required double upperAmount,
  //     required String externalId}) async {
  //   String fontStyle1 = "^A1N,24,12";
  //   String fontStyle2 = "^A1N,14,12";
  //   int xAxis = 175;
  //   int xAxis2 = 30;
  //   int xAxis3 = 145;
  //   int referenceNo = 78;
  //   int date = referenceNo + 55;
  //   int plate = date + 70;
  //   int make = plate + 65;
  //   int color = make + 60;
  //   int location = color + 55;
  //   DateTime now = await timeNTP.getTimeWithUKTime();
  //   int road = location;
  //   int issueTime = color + 220;
  //   int timeFirstSeen = issueTime + 60;
  //   int wardenId = timeFirstSeen + 58;
  //   int desc = wardenId + (205 - 67);
  //   int upper = desc + 102;
  //   int lower = upper + 45;
  //   int referenceNo2 = upper + 445;
  //   int date2 = referenceNo2 + 60;
  //   int plate2 = date2 + 60;
  //   int barcode = plate2 + 70;
  //   List<int> bytes = [];

  //   final profile = await CapabilityProfile.load();

  //   final generator = Generator(PaperSize.mm80, profile);
  //   String locationInfo =
  //       "$road^FB400,7,3,L,0$fontStyle2^FD${locationName.Name}\\&${isTextNull(locationName.Address1) ? " " : locationName.Address1}\\&${isTextNull(locationName.Town) ? " " : locationName.Town}\\&${isTextNull(locationName.County) ? " " : locationName.County}\\&${isTextNull(locationName.Postcode) ? " " : locationName.Postcode}^FS^FO$xAxis";

  //   String lowerPrintText =
  //       "$lower^FB400,3,3,L,0$fontStyle1^FD$lowerAmount^FS^FO$xAxis3";
  //   String upperPrintText =
  //       "$upper^FB400,3,3,L,0$fontStyle1^FD$upperAmount^FS^FO${xAxis3 + 115}";
  //   String externalIdSpace = "$wardenId$fontStyle1^FD$externalId^FS^FO$xAxis2";
  //   bytes += generator.text(
  //       '! U1 setvar "media.type" "label" ! U1 setvar "media.sense_mode" "bar" ! U1 setvar "device.languages" "zpl" ! U1 setvar "device.pnp_option" "zpl" ^XA^POI^FO$xAxis,$referenceNo$fontStyle1^FD${physicalPCN.reference}^FS^FO$xAxis,$date^A,$fontStyle1^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis,$plate$fontStyle1^FD${physicalPCN.plate}^FS^FO$xAxis,$make$fontStyle1^FD${physicalPCN.make}^FS^FO$xAxis,$color$fontStyle1^FD${physicalPCN.colour}^FS^FO$xAxis,$locationInfo,$issueTime$fontStyle1^FD${DateFormat('HH:mm dd-MM-yyyy').format(timeHelper.ukTimeZoneConversion(physicalPCN.eventDateTime as DateTime))}^FS^FO$xAxis,$timeFirstSeen$fontStyle1^FD${DateFormat('HH:mm dd-MM-yyyy').format(timeHelper.ukTimeZoneConversion(physicalPCN.contraventionDetailsWarden?.FirstObserved as DateTime))}^FS^FO${xAxis3 + 110},$externalIdSpace,$desc^FB550,4,3,L,0$fontStyle2^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS^FO${xAxis3 + 115},$upperPrintText, $lowerPrintText, $referenceNo2$fontStyle1^FD${physicalPCN.reference}^FS^FO$xAxis3,$date2$fontStyle1^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis3,$plate2$fontStyle1^FD${physicalPCN.plate}^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS^XZ');

  //   await printEscPos(bytes, generator);
  // }

  int calculatorItem(String? text) {
    int num;
    if (text == null || text.isEmpty) {
      num = 0;
    } else {
      num = 30;
    }
    return num;
  }

  Future printPhysicalPCN(
      {required Contravention physicalPCN,
      required Location locationName,
      required double lowerAmount,
      required double upperAmount,
      required String externalId}) async {
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 145;
    int referenceNo = 80;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 65;
    int location = color + 55;
    DateTime now = await timeNTP.get();
    int road = location + calculatorItem(locationName.Address1);
    int town = road + calculatorItem(locationName.Town);
    int county = town + calculatorItem(locationName.County);
    int postCode = county + calculatorItem(locationName.Postcode);

    // int issueTime = postCode +
    //     45 +
    //     calculatorLocation([
    //       locationName.Address1,
    //       locationName.Town,
    //       locationName.County,
    //       locationName.Postcode
    //     ]);
    int issueTime = color + 220;
    int timeFirstSeen = issueTime + 60;
    int wardenId = timeFirstSeen + 55;
    int desc = wardenId + (205 - 65);
    int upper = desc + 101;
    int lower = upper + 42;
    int referenceNo2 = upper + 441;
    int date2 = referenceNo2 + 60;
    int plate2 = date2 + 60;
    int barcode = plate2 + 70;
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, profile);
    String roadString =
        "$road^FB400,3,3,L,0^FD${isTextNull(locationName.Address1) ? " " : locationName.Address1}^FS^FO$xAxis";

    String townString =
        "$town^FB400,3,3,L,0^FD${isTextNull(locationName.Town) ? " " : locationName.Town}^FS^FO$xAxis";

    String countyString =
        "$county^FB400,3,3,L,0^FD${isTextNull(locationName.County) ? " " : locationName.County}^FS^FO$xAxis";

    String postCodeString =
        "$postCode^FB400,3,3,L,0^FD${isTextNull(locationName.Postcode) ? " " : locationName.Postcode}^FS^FO$xAxis";
    String lowerPrintText = "$lower^FB400,3,3,L,0^FD$lowerAmount^FS^FO$xAxis3";
    String upperPrintText =
        "$upper^FB400,3,3,L,0^FD$upperAmount^FS^FO${xAxis3 + 115}";
    String externalIdSpace = "$wardenId^FD$externalId^FS^FO$xAxis2";
    bytes += generator.text(
        '! U1 setvar "device.languages" "zpl" ! U1 setvar "device.pnp_option" "zpl" ^XA^MNN^LL1886^POI^CFA,20^FO$xAxis,$referenceNo^FD${physicalPCN.reference}^FS^FO$xAxis,$date^A,^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis,$plate^FD${physicalPCN.plate}^FS^FO$xAxis,$make^FD${physicalPCN.make}^FS^FO$xAxis,$color^FD${physicalPCN.colour}^FS^FO$xAxis,$location^FB400,3,3,L,0^FD${locationName.Name}^FS^FO$xAxis,$roadString,$townString,$countyString,$postCodeString,$issueTime^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.eventDateTime as DateTime)}^FS^FO$xAxis,$timeFirstSeen^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.contraventionDetailsWarden?.FirstObserved as DateTime)}^FS^FO${xAxis3 + 110},$externalIdSpace,$desc^FB500,3,3,L,0^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS^FO${xAxis3 + 115},$upperPrintText, $lowerPrintText, $referenceNo2^FD${physicalPCN.reference}^FS^FO$xAxis3,$date2^FD${DateFormat('dd-MM-yyyy').format(now)}^FS^FO$xAxis3,$plate2^FD${physicalPCN.plate}^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS^XZ');

    printEscPos(bytes, generator);
  }

  /// print ticket
  Future<void> printEscPos(List<int> bytes, Generator generator) async {
    if (selectedPrinter == null) return;
    var bluetoothPrinter = selectedPrinter!;
    log("_printEscPos: ${bluetoothPrinter.typePrinter.toString()}");
    await printerManager
        .connect(
          type: bluetoothPrinter.typePrinter,
          model: BluetoothPrinterInput(
            name: bluetoothPrinter.deviceName,
            address: bluetoothPrinter.address!,
            isBle: bluetoothPrinter.isBle ?? false,
            autoConnect: false,
          ),
        )
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => false,
        );

    pendingTask = [];
    if (Platform.isAndroid) {
      pendingTask = bytes;
    }

    if (bluetoothPrinter.typePrinter == PrinterType.bluetooth &&
        Platform.isAndroid) {
      if (currentStatus == BTStatus.connected) {
        var result = await printerManager.send(
            type: bluetoothPrinter.typePrinter, bytes: bytes);
        log(result.toString());
        pendingTask = [];
      }
    } else {
      printerManager.send(type: bluetoothPrinter.typePrinter, bytes: bytes);
    }
  }

  void disposePrinter() {
    subscription?.cancel();
    subscriptionBtStatus?.cancel();
  }

  Future<void> resetPrinterConnection() async {
    await subscription?.cancel();
    await subscriptionBtStatus?.cancel();
    // isBle = false;
    isConnected = false;
    // printerManager = PrinterManager.instance;
    // devices = <BluetoothPrinter>[];
    // currentStatus = BTStatus.none;
    // pendingTask = [];
    // selectedPrinter = null;
  }
}

final bluetoothPrinterHelper = BluetoothPrinterHelper();

class BluetoothPrinter {
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;

  BluetoothPrinter({
    this.deviceName,
    this.address,
    this.port,
    this.state,
    this.vendorId,
    this.productId,
    this.typePrinter = PrinterType.bluetooth,
    this.isBle = false,
  });
}

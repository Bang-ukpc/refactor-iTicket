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

  String formatDateTime(DateTime date) {
    return DateFormat('HH:mm dd-MM-yyyy').format(date);
  }

  Future printReceiveTest() async {
    String fontStyle1 = "^A1N,24,12";
    String fontStyle2 = "^A1N,14,12";
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 145;
    int xAxis4 = 100;

    int referenceNo = 78;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 60;
    int location = color + 55;
    int issueTime = location + 165;
    int timeFirstSeen = issueTime + 60;
    int desc = timeFirstSeen + 200;
    int referenceNo2 = desc + 543;
    int date2 = referenceNo2 + 60;
    int plate2 = date2 + 60;
    int barcode = plate2 + 70;

    DateTime now = await timeNTP.getTimeWithUKTime();
    final dateFormatted = DateFormat('dd-MM-yyyy').format(now);
    final dateTimeFormatted = formatDateTime(now);

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    bytes += generator.text('''^XA
    ^MNM
    ^LL1994
    ^POI
    ^FO$xAxis,$referenceNo$fontStyle1^FD1234567890123^FS
    ^FO$xAxis,$date^A,$fontStyle1^FD$dateFormatted^FS
    ^FO$xAxis,$plate$fontStyle1^FDXX99XXX^FS
    ^FO$xAxis,$make$fontStyle1^FDMAKE^FS
    ^FO$xAxis,$color$fontStyle1^FDCOLOUR^FS
    ^FO$xAxis,$location$fontStyle2^FDVOID A2^FS
    ^FO$xAxis,${location + 40}$fontStyle2^FDVOID A3^FS
    ^FO$xAxis,${location + 80}$fontStyle2^FDVOID A4^FS
    ^FO$xAxis,${location + 120}$fontStyle2^FDVOID A5^FS
    ^FO$xAxis,$issueTime$fontStyle1^FD$dateTimeFormatted^FS
    ^FO$xAxis,$timeFirstSeen$fontStyle1^FD$dateTimeFormatted^FS
    ^FO$xAxis2,$desc$fontStyle2^FDVOID 02^FS
    ^FO$xAxis2,${desc + 20}$fontStyle2^FDVOID 03^FS
    ^FO$xAxis2,${desc + 40}$fontStyle2^FDVOID 04^FS
    ^FO$xAxis3,$referenceNo2$fontStyle1^FD1234567890123^FS
    ^FO$xAxis3,$date2$fontStyle1^FD$dateFormatted^FS
    ^FO$xAxis3,$plate2$fontStyle1^FDXX99XXX^FS
    ^FO$xAxis4,$barcode^BY3^BC,100,N,N,N,A^FD1234567890123^FS
    ^XZ''');

    log('''^XA
    ^MNM
    ^LL1994
    ^POI
    ^FO$xAxis,$referenceNo$fontStyle1^FD1234567890123^FS
    ^FO$xAxis,$date^A,$fontStyle1^FD$dateFormatted^FS
    ^FO$xAxis,$plate$fontStyle1^FDXX99XXX^FS
    ^FO$xAxis,$make$fontStyle1^FDMAKE^FS
    ^FO$xAxis,$color$fontStyle1^FDCOLOUR^FS
    ^FO$xAxis,$location$fontStyle2^FDVOID A2^FS
    ^FO$xAxis,${location + 40}$fontStyle2^FDVOID A3^FS
    ^FO$xAxis,${location + 80}$fontStyle2^FDVOID A4^FS
    ^FO$xAxis,${location + 120}$fontStyle2^FDVOID A5^FS
    ^FO$xAxis,$issueTime$fontStyle1^FD$dateTimeFormatted^FS
    ^FO$xAxis,$timeFirstSeen$fontStyle1^FD$dateTimeFormatted^FS
    ^FO$xAxis2,$desc$fontStyle2^FDVOID 02^FS
    ^FO$xAxis2,${desc + 20}$fontStyle2^FDVOID 03^FS
    ^FO$xAxis2,${desc + 40}$fontStyle2^FDVOID 04^FS
    ^FO$xAxis3,$referenceNo2$fontStyle1^FD1234567890123^FS
    ^FO$xAxis3,$date2$fontStyle1^FD$dateFormatted^FS
    ^FO$xAxis3,$plate2$fontStyle1^FDXX99XXX^FS
    ^FO$xAxis4,$barcode^BY3^BC,100,N,N,N,A^FD1234567890123^FS
    ^XZ''');

    await printEscPos(bytes, generator);
  }

  bool isTextNull(String? text) {
    return text == null || text.isEmpty;
  }

  Future printPhysicalPCN(
      {required Contravention physicalPCN,
      required Location locationName,
      required double lowerAmount,
      required double upperAmount,
      required String externalId}) async {
    String fontStyle1 = "^A1N,24,12";
    String fontStyle2 = "^A1N,14,12";
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 145;
    int xAxis4 = 100;

    int referenceNo = 78;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 60;
    int location = color + 55;
    int road = location;
    int issueTime = color + 220;
    int timeFirstSeen = issueTime + 60;
    int wardenId = timeFirstSeen + 58;
    int desc = wardenId + (205 - 41);
    int upper = desc + 102;
    int lower = upper + 45;
    int referenceNo2 = upper + 445;
    int date2 = referenceNo2 + 60;
    int plate2 = date2 + 60;
    int barcode = plate2 + 70;

    DateTime now = await timeNTP.getTimeWithUKTime();
    final timeFormatted = DateFormat('dd-MM-yyyy').format(now);
    final eventDateTime = formatDateTime(
        timeHelper.ukTimeZoneConversion(physicalPCN.eventDateTime as DateTime));
    final firstObservedTime = formatDateTime(timeHelper.ukTimeZoneConversion(
        physicalPCN.contraventionDetailsWarden?.FirstObserved as DateTime));

    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    bytes += generator.text('''^XA
    ^MNM
    ^LL1994
    ^POI
    ^FO$xAxis,$referenceNo$fontStyle1^FD${physicalPCN.reference}^FS
    ^FO$xAxis,$date^A,$fontStyle1^FD$timeFormatted^FS
    ^FO$xAxis,$plate$fontStyle1^FD${physicalPCN.plate}^FS
    ^FO$xAxis,$make$fontStyle1^FD${physicalPCN.make}^FS
    ^FO$xAxis,$color$fontStyle1^FD${physicalPCN.colour}^FS
    ^FO$xAxis,$road^FB400,7,3,L,0$fontStyle2^FD${locationName.Name}\\&${isTextNull(locationName.Address1) ? " " : locationName.Address1}\\&${isTextNull(locationName.Town) ? " " : locationName.Town}\\&${isTextNull(locationName.County) ? " " : locationName.County}\\&${isTextNull(locationName.Postcode) ? " " : locationName.Postcode}^FS
    ^FO$xAxis,$issueTime$fontStyle1^FD$eventDateTime^FS
    ^FO$xAxis,$timeFirstSeen$fontStyle1^FD$firstObservedTime^FS
    ^FO${xAxis3 + 110},$wardenId$fontStyle1^FD$externalId^FS
    ^FO$xAxis2,$desc^FB550,4,3,L,0$fontStyle2^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS
    ^FO${xAxis3 + 115},$upper^FB400,3,3,L,0$fontStyle1^FD$upperAmount^FS
    ^FO${xAxis3 + 115},$lower^FB400,3,3,L,0$fontStyle1^FD$lowerAmount^FS
    ^FO$xAxis3,$referenceNo2$fontStyle1^FD${physicalPCN.reference}^FS
    ^FO$xAxis3,$date2$fontStyle1^FD$timeFormatted^FS
    ^FO$xAxis3,$plate2$fontStyle1^FD${physicalPCN.plate}^FS
    ^FO$xAxis4,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS
    ^XZ''');

    log('''^XA
    ^MNM
    ^LL1994
    ^POI
    ^FO$xAxis,$referenceNo$fontStyle1^FD${physicalPCN.reference}^FS
    ^FO$xAxis,$date^A,$fontStyle1^FD$timeFormatted^FS
    ^FO$xAxis,$plate$fontStyle1^FD${physicalPCN.plate}^FS
    ^FO$xAxis,$make$fontStyle1^FD${physicalPCN.make}^FS
    ^FO$xAxis,$color$fontStyle1^FD${physicalPCN.colour}^FS
    ^FO$xAxis,$road^FB400,7,3,L,0$fontStyle2^FD${locationName.Name}\\&${isTextNull(locationName.Address1) ? " " : locationName.Address1}\\&${isTextNull(locationName.Town) ? " " : locationName.Town}\\&${isTextNull(locationName.County) ? " " : locationName.County}\\&${isTextNull(locationName.Postcode) ? " " : locationName.Postcode}^FS
    ^FO$xAxis,$issueTime$fontStyle1^FD$eventDateTime^FS
    ^FO$xAxis,$timeFirstSeen$fontStyle1^FD$firstObservedTime^FS
    ^FO${xAxis3 + 110},$wardenId$fontStyle1^FD$externalId^FS
    ^FO$xAxis2,$desc^FB550,4,3,L,0$fontStyle2^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS
    ^FO${xAxis3 + 115},$upper^FB400,3,3,L,0$fontStyle1^FD$upperAmount^FS
    ^FO${xAxis3 + 115},$lower^FB400,3,3,L,0$fontStyle1^FD$lowerAmount^FS
    ^FO$xAxis3,$referenceNo2$fontStyle1^FD${physicalPCN.reference}^FS
    ^FO$xAxis3,$date2$fontStyle1^FD$timeFormatted^FS
    ^FO$xAxis3,$plate2$fontStyle1^FD${physicalPCN.plate}^FS
    ^FO$xAxis4,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS
    ^XZ''');

    await printEscPos(bytes, generator);
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

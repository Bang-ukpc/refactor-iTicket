import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/location.dart';
import 'package:intl/intl.dart';

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
          BluetoothPrinter deviceSelected = devices.firstWhere((device) =>
              device.deviceName!.toUpperCase().contains('ezpcn'.toUpperCase()));
          selectDevice(deviceSelected);
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

  Future printReceiveTest() async {
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 135;
    int referenceNo = 85;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 65;
    int location = color + 50;
    int issueTime = location + 170;
    int timeFirstSeen = issueTime + 60;
    int desc = timeFirstSeen + 200;
    int referenceNo2 = desc + 540;
    int date2 = referenceNo2 + 60;
    int plate2 = date2 + 60;
    int barcode = plate2 + 70;
    List<int> bytes = [];

    final profile = await CapabilityProfile.load();

    final generator = Generator(PaperSize.mm80, profile);
    bytes += generator.text(
        '! U1 setvar "device.languages" "zpl" ! U1 setvar "device.pnp_option" "zpl" ^XA^MNN^LL1886^POI^CFA,20^FO$xAxis,$referenceNo^FD1234567890123^FS^FO$xAxis,$date^A,^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$plate^FDXX99XXX^FS^FO$xAxis,$make^FDMAKE^FS^FO$xAxis,$color^FDCOLOUR^FS^FO$xAxis,$location^FDVOID A2^FS^FO$xAxis,${location + 40}^FDVOID A3^FS^FO$xAxis,${location + 80}^FDVOID A4^FS^FO$xAxis,${location + 120}^FDVOID A5^FS^FO$xAxis,$issueTime^FD${DateFormat('HH:mm dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$timeFirstSeen^FD${DateFormat('HH:mm dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis2,$desc^FDVOID 02^FS^FO$xAxis2,${desc + 20}^FDVOID 03^FS^FO$xAxis2,${desc + 40}^FDVOID 04^FS^FO$xAxis3,$referenceNo2^FD1234567890123^FS^FO$xAxis3,$date2^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis3,$plate2^FDXX99XXX^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD1234567890123^FS^XZ');

    printEscPos(bytes, generator);
  }

  int calculatorItem(String? text) {
    int num;
    if (text == null || text.isEmpty) {
      num = 0;
    } else {
      num = 30;
    }
    return num;
  }

  int calculatorLocation(List<String?> listText) {
    int sum = 0;
    for (int i = 0; i < listText.length; i++) {
      sum += calculatorItem(listText[i]);
    }
    return sum;
  }

  bool isTextNull(String? text) {
    return text == null || text.isEmpty;
  }

  Future printPhysicalPCN(Contravention physicalPCN, Location locationName,
      double lowerAmount, double upperAmount, String externalId) async {
    int xAxis = 175;
    int xAxis2 = 30;
    int xAxis3 = 135;
    int referenceNo = 75;
    int date = referenceNo + 55;
    int plate = date + 70;
    int make = plate + 65;
    int color = make + 65;
    int location = color + 55;

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
        '! U1 setvar "device.languages" "zpl" ! U1 setvar "device.pnp_option" "zpl" ^XA^MNN^LL1886^POI^CFA,20^FO$xAxis,$referenceNo^FD${physicalPCN.reference}^FS^FO$xAxis,$date^A,^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$plate^FD${physicalPCN.plate}^FS^FO$xAxis,$make^FD${physicalPCN.make}^FS^FO$xAxis,$color^FD${physicalPCN.colour}^FS^FO$xAxis,$location^FB400,3,3,L,0^FD${locationName.Name}^FS^FO$xAxis,$roadString,$townString,$countyString,$postCodeString,$issueTime^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.eventDateTime as DateTime)}^FS^FO$xAxis,$timeFirstSeen^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.contraventionDetailsWarden?.FirstObserved as DateTime)}^FS^FO${xAxis3 + 110},$externalIdSpace,$desc^FB500,3,3,L,0^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS^FO${xAxis3 + 115},$upperPrintText, $lowerPrintText, $referenceNo2^FD${physicalPCN.reference}^FS^FO$xAxis3,$date2^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis3,$plate2^FD${physicalPCN.plate}^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS^XZ');

    printEscPos(bytes, generator);
  }

  /// print ticket
  void printEscPos(List<int> bytes, Generator generator) async {
    if (selectedPrinter == null) return;
    var bluetoothPrinter = selectedPrinter!;
    log("_printEscPos: ${bluetoothPrinter.typePrinter.toString()}");
    await printerManager.connect(
      type: bluetoothPrinter.typePrinter,
      model: BluetoothPrinterInput(
        name: bluetoothPrinter.deviceName,
        address: bluetoothPrinter.address!,
        isBle: bluetoothPrinter.isBle ?? false,
        autoConnect: false,
      ),
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

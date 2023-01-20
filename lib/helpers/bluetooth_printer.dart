import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/models/contravention.dart';
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
  int count = 0;

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
      onDone: () {
        log('ao ma canada 1');
      },
      onError: (err) {
        log('ao ma');
      },
      cancelOnError: true,
    );
  }

  void initConnect({required bool isLoading}) {
    subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen(
      (status) {
        log(' ----------------- status bt $status ------------------ ');
        currentStatus = status;
        if (status == BTStatus.connected) {
          isConnected = true;
        }
        if (status == BTStatus.none) {
          isConnected = false;
          if (count == 1 && isLoading == true) {
            NavigationService.navigatorKey.currentState!.pop();
          }
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
          if (isLoading == true) {
            NavigationService.navigatorKey.currentState!.pop();
          }
        }
        count++;
      },
      onDone: () {
        log('ao ma canada 2');
      },
      onError: (err) {
        log('ao ma');
      },
      cancelOnError: true,
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
        "^XA^MNN^LL1886^POI^CFA,20^FO$xAxis,$referenceNo^FD1234567890123^FS^FO$xAxis,$date^A,^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$plate^FDXX99XXX^FS^FO$xAxis,$make^FDMAKE^FS^FO$xAxis,$color^FDCOLOUR^FS^FO$xAxis,$location^FDVOID A2^FS^FO$xAxis,${location + 40}^FDVOID A3^FS^FO$xAxis,${location + 80}^FDVOID A4^FS^FO$xAxis,${location + 120}^FDVOID A5^FS^FO$xAxis,$issueTime^FD${DateFormat('HH:mm dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$timeFirstSeen^FD${DateFormat('HH:mm dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis2,$desc^FDVOID 02^FS^FO$xAxis2,${desc + 20}^FDVOID 03^FS^FO$xAxis2,${desc + 40}^FDVOID 04^FS^FO$xAxis3,$referenceNo2^FD1234567890123^FS^FO$xAxis3,$date2^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis3,$plate2^FDXX99XXX^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD1234567890123^FS^XZ");

    printEscPos(bytes, generator);
  }

  Future printPhysicalPCN(
      Contravention physicalPCN, String locationName) async {
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
        "^XA^MNN^LL1886^POI^CFA,20^FO$xAxis,$referenceNo^FD${physicalPCN.reference}^FS^FO$xAxis,$date^A,^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis,$plate^FD${physicalPCN.plate}^FS^FO$xAxis,$make^FD${physicalPCN.make}^FS^FO$xAxis,$color^FD${physicalPCN.colour}^FS^FO$xAxis,$location^FB400,3,3,L,0^FD$locationName^FS^FO$xAxis,$issueTime^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.eventDateTime as DateTime)}^FS^FO$xAxis,$timeFirstSeen^FD${DateFormat('HH:mm dd-MM-yyyy').format(physicalPCN.contraventionDetailsWarden?.FirstObserved as DateTime)}^FS^FO$xAxis2,$desc^FB500,3,3,L,0^FD${physicalPCN.reason?.contraventionReasonTranslations?[0].detail ?? ""}^FS^FO$xAxis3,$referenceNo2^FD${physicalPCN.reference}^FS^FO$xAxis3,$date2^FD${DateFormat('dd-MM-yyyy').format(DateTime.now())}^FS^FO$xAxis3,$plate2^FD${physicalPCN.plate}^FS^FO100,$barcode^BY3^BC,100,N,N,N,A^FD${physicalPCN.reference}^FS^XZ");

    printEscPos(bytes, generator);
  }

  /// print ticket
  void printEscPos(List<int> bytes, Generator generator) async {
    count = 0;
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
    count = 0;
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

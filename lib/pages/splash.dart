/// @author Matthew Smith
/// @email Mattdsmith228@gmail.com
/// @file splash.dart

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:go_router/go_router.dart';

class Splash extends StatelessWidget {
  const Splash({Key? key}) : super(key: key);

  void getDevice(BuildContext context) async {
    //Services to communicate with
    List<String> serviceUuids = [
      "00000000-0000-beef-002f-400000000000", //BleepingLibrary
      "00000000-0000-beef-002f-a00000000000", //BleepingCustomConfigs
      "00000000-0000-beef-002f-320000000000", //Bleeping
    ];

    //UUID's to scan for
    List<String> filterUuids = [
      "00000000-0000-beef-001f-320000000000", //BleepingLibraryDevice
    ];
    List<RequestFilterBuilder> filterList = [
      RequestFilterBuilder(services: filterUuids)
    ];

    String getStringFromBytes(ByteData data) {
      final buffer = data.buffer;
      var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      return utf8.decode(list);
    }

    _loadingModal(context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              height: 350,
              constraints: const BoxConstraints(maxHeight: 350, maxWidth: 350),
              child: const Padding(
                padding: EdgeInsets.all(50.0),
                child: SpinKitWave(
                    color: Colors.black,
                    size: 175,
                    type: SpinKitWaveType.center),
              ),
            ),
          );
        },
      );
    }

    _dismissDialog() {
      Navigator.pop(context);
    }

    try {
      final device = await FlutterWebBluetooth.instance.requestDevice(
          RequestOptionsBuilder(filterList, optionalServices: serviceUuids));
      _loadingModal(context);
      debugPrint("Device got! ${device.name}, ${device.id}");

      // check if configured
      // 00000000-0000-beef-002f-321203000000

      await device.connect(timeout: const Duration(seconds: 10));
      log("Connected");
      await Future.delayed(const Duration(seconds: 1));
      final services = await device.discoverServices();
      for (var element in services) {
        log("Found Service: " + element.uuid.toString());
      }
      await Future.delayed(const Duration(seconds: 1));
      log("Got services");
      final propService = services.firstWhere(
          (service) => service.uuid == "00000000-0000-beef-002f-320000000000");
      log("found service");
      log("TEST:");
      final configBit = await propService
          .getCharacteristic("00000000-0000-beef-002f-321203000000");
      log("found configbit characteristic");

      ByteData bConfigBit =
          await configBit.readValue(timeout: const Duration(seconds: 10));

      String sConfigBit = getStringFromBytes(bConfigBit);
      log("[Bleep] Config bit: $sConfigBit");
      switch (sConfigBit) {
        case "0":
          log("[Bleep] Device Not HW Configured");
          context.goNamed('provision', extra: device); // send to provision
          break;
        case "1":
          log("[Bleep] Device Hw Configured");
          context.goNamed('config', extra: device); // send to config
          break;
        default:
          log("Unknown config bit [ $sConfigBit ]");
          //handle unknown config

          break;
      }
    } on DeviceNotFoundError {
      log("Device not found");
      //_dismissDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 10)),
              Center(
                child: Image.asset('lib/res/logo.png'),
              ),
              const Text("Press Scan to start"),
              const Padding(padding: EdgeInsets.all(8)),
              ElevatedButton(
                onPressed: () {
                  getDevice(context);
                },
                child: const Text("Scan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

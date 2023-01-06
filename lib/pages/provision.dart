/// @author Matthew Smith
/// @email Mattdsmith228@gmail.com
/// @file provision.dart

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';

class Provision extends StatefulWidget {
  final BluetoothDevice device;
  //final Device device;
  const Provision({Key? key, required this.device}) : super(key: key);

  @override
  State<Provision> createState() => _Provision();
}

class _Provision extends State<Provision> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  void handleWifiSetup(String wifiName, String wifiPass) async {
    await widget.device.connect(timeout: const Duration(seconds: 10));
    final services = await widget.device.discoverServices();
    final wifiService = services.firstWhere(
        (service) => service.uuid == "00000000-0000-beef-002f-400000000000");

    final configService = services.firstWhere(
        (service) => service.uuid == "00000000-0000-beef-002f-320000000000");

    final cWifiName = await wifiService
        .getCharacteristic("00000000-0000-beef-002f-400203000000");

    final cWifiPass = await wifiService
        .getCharacteristic("00000000-0000-beef-002f-400302000000");

    final cConfigBit = await configService
        .getCharacteristic("00000000-0000-beef-002f-321203000000");

    await cWifiName
        .writeValueWithResponse(const AsciiEncoder().convert(wifiName));
    log("[Bleep] Set Wifi Name!");
    await cWifiPass
        .writeValueWithResponse(const AsciiEncoder().convert(wifiPass));
    log("[Bleep] Set Wifi Password!");
    await cConfigBit.writeValueWithResponse(const AsciiEncoder().convert("1"));
    log("[Bleep] Set ConfigBit to 1");

    setState(() {
      _dismissDialog();
    });
  }

  _dismissDialog() {
    Navigator.pop(context);
  }

  _showSimpleModalDialog(context) {
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
                  color: Colors.black, size: 175, type: SpinKitWaveType.center),
            ),
          ),
        );
      },
    );
  }

  Widget wifiForm() {
    final TextEditingController wifiNameC = TextEditingController();
    final TextEditingController wifiPassC = TextEditingController();

    String getName() {
      return wifiNameC.text;
    }

    String getPass() {
      return wifiPassC.text;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: wifiNameC,
            decoration: const InputDecoration(
              hintText: "Wifi Name",
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter wifi name';
              }
              return null;
            },
          ),
          TextFormField(
            controller: wifiPassC,
            enableSuggestions: false,
            autocorrect: false,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Wifi Password",
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Please enter wifi password';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              child: const Text("Provision"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Process data.
                  _showSimpleModalDialog(context);
                  handleWifiSetup(getName(), getPass());
                  //Handle request
                  log("[Bleep] [Provision] Wifi Name: ${getName()}");
                  log("[Bleep] [Provision] Wifi Pass: ${getPass()}");
                }
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 10)),
              Center(
                child: Image.asset('lib/res/logo.png'),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 10)),
              const Text(
                "Device\nProvisioning",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
              Container(
                width: 275,
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: wifiForm(),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                height: 50,
                padding: const EdgeInsets.all(10),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

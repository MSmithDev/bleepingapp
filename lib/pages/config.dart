/// @author Matthew Smith
/// @email Mattdsmith228@gmail.com
/// @file config.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';

import '../helpers/uuid_helper.dart';

class Config extends StatefulWidget {
  //todo remove commented line
  final BluetoothDevice device;
  const Config({Key? key, required this.device}) : super(key: key);
  //const Config({Key? key}) : super(key: key); // temp

  @override
  State<Config> createState() => Characteristic();
}

class Characteristic extends State<Config> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final UUIDHelper helper = UUIDHelper();

  //characteristic variables
  List<String> stringValues = [];
  List<String> hexValues = [];
  List<BluetoothCharacteristic> customList = [];
  List<TextEditingController> valController = [];

  //get current list of custom characteristics
  Future<List<BluetoothCharacteristic>> getList() async {
    await widget.device.connect(timeout: const Duration(seconds: 10));
    final services = await widget.device.discoverServices();
    final customService = services.firstWhere(
        (service) => service.uuid == "00000000-0000-beef-002f-a00000000000");
    final customChar = await customService.getCharacteristics();
    setState(() {
      customList = customChar;
    });

    return customChar;
  }

  //used for builder
  //TODO: possible better way?
  Future<List<BluetoothCharacteristic>> getBuildList() {
    return Future((() {
      return customList;
    }));
  }

  @override
  void initState() {
    getList();
    super.initState();
  }

  _dismissDialog() {
    Navigator.pop(context);
  }

  //TODO: Decide to use or not.
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
                  color: Colors.black, size: 175, type: SpinKitWaveType.center),
            ),
          ),
        );
      },
    );
  }

  String getStringFromBytes(ByteData data) {
    final buffer = data.buffer;
    var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return utf8.decode(list);
  }

  void getValue(int index, BluetoothCharacteristic characteristic) async {
    ByteData data = await characteristic.readValue();
    String value = getStringFromBytes(data);
    String hex = "";
    data.buffer
        .asInt8List(data.offsetInBytes, data.lengthInBytes)
        .forEach((element) {
      hex = hex + element.toRadixString(16);
    });
    setState(() {
      stringValues[index] = value;
      hexValues[index] = hex;
    });
  }

  void setValue(
      int index, String value, BluetoothCharacteristic characteristic) async {
    var data = const AsciiEncoder().convert(value);
    await characteristic.writeValueWithResponse(data);
    String hex = "";
    data.buffer
        .asInt8List(data.offsetInBytes, data.lengthInBytes)
        .forEach((element) {
      hex = hex + element.toRadixString(16);
    });
    setState(() {
      stringValues[index] = value;
      hexValues[index] = hex;
    });
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
                "Device\nConfiguration",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
              Container(
                width: 350,
                height: 500,
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: devWidget(),
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

  Widget devWidget() {
    return Form(
      key: _formKey,
      child: FutureBuilder(
        future: getBuildList(),
        builder:
            (context, AsyncSnapshot<List<BluetoothCharacteristic>> snapshot) {
          if (!snapshot.hasData) {
            //todo implement
            return const CircularProgressIndicator();
          } else {
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  stringValues.add("");
                  hexValues.add("");
                  valController.add(TextEditingController());
                  return ExpansionTile(
                    title: Text(helper.getName(snapshot.data![index].uuid)),
                    expandedAlignment: Alignment.topLeft,
                    children: [
                      Row(
                        children: [
                          Text("Value: ${stringValues[index]}"),
                        ],
                      ),
                      Row(
                        children: [
                          Text("Hex: ${hexValues[index]}"),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              //check if read is allowed
                              onPressed: snapshot.data![index].properties.read
                                  ? () => getValue(index, snapshot.data![index])
                                  : null,
                              child: const Text("Read")),
                          const Padding(padding: EdgeInsets.all(5)),
                          ElevatedButton(
                              //check if write is allowed
                              onPressed: snapshot.data![index].properties.write
                                  ? () {
                                      setValue(index, valController[index].text,
                                          snapshot.data![index]);
                                    }
                                  : null,
                              child: const Text("Write")),
                          const Padding(padding: EdgeInsets.all(5)),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: valController[index],
                              enableSuggestions: false,
                              autocorrect: false,
                              obscureText: false,
                              decoration: const InputDecoration(
                                hintText: "Value",
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  );
                });
          }
        },
      ),
    );
  }
}

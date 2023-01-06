import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

class UUIDHelper {
  String jsonString = "";

  UUIDHelper() {
    init();
  }
  Map<String, dynamic> uuidMap = {};
  Future init() async {
    log("[Bleep] FUTURE Init UUIDHelper");

    var response = await rootBundle.loadString('web/res/uuids.json');
    log("load String done");
    log(response);
    jsonString = response;

    Map<String, dynamic> map = jsonDecode(jsonString);
    uuidMap = map;
  }

  String getName(String uuid) {
    log("[Helper] Got uuid: " + uuid);
    if (uuidMap.containsKey(uuid)) {
      Map<String, dynamic> uuidObj = uuidMap[uuid];

      log('[Helper] Has Key: ' + uuidObj['title'].toString());
      return uuidObj['title'].toString();
    } else {
      log("[Helper] No key!");
      return uuid;
    }
  }
}

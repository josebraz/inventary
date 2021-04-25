
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {

  static Future<File> getLogFile() async {
    final directory = await getApplicationSupportDirectory();
    var path = "${directory.path}/log.txt";
    return File(path);
  }

  static Future<String> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId;
    }
  }

  static void sendStatistics() async {
    final logFile = await getLogFile();
    final deviceId = await getDeviceId();
    final logText = await logFile.readAsString();

    final Email email = Email(
      body: 'Em anexo, segue o arquivo de logs\n\n $logText',
      subject: 'Estatisticas do App Inventary - deviceId: $deviceId',
      recipients: ['josehhbraz@gmail.com', 'dudabosel@gmail.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  static Future<bool> isFreshInstall() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('freshInstall') ?? true;
    return true;
  }

  static Future<void> setFreshInstall() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('freshInstall', false);
  }
}
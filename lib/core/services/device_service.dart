import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  Future<String> name() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return '${android.manufacturer} ${android.model}';
      }
      if (Platform.isIOS) return (await info.iosInfo).modelName;
    } catch (_) {}
    return Platform.operatingSystem;
  }
}

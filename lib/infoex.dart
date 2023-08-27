import 'infoex_platform_interface.dart';

class Infoex {
  Future<String?> getPlatformVersion() {
    return InfoexPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> getIE(String url) {
    return InfoexPlatform.instance.getIE(url);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'infoex_platform_interface.dart';

/// An implementation of [InfoexPlatform] that uses method channels.
class MethodChannelInfoex extends InfoexPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('infoex');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<dynamic> getIE(String url) async {
    final result = await methodChannel.invokeMethod<dynamic>('ie', url);
    return result;
  }
}

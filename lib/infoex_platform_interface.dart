import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'infoex_method_channel.dart';

abstract class InfoexPlatform extends PlatformInterface {
  /// Constructs a InfoexPlatform.
  InfoexPlatform() : super(token: _token);

  static final Object _token = Object();

  static InfoexPlatform _instance = MethodChannelInfoex();

  /// The default instance of [InfoexPlatform] to use.
  ///
  /// Defaults to [MethodChannelInfoex].
  static InfoexPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InfoexPlatform] when
  /// they register themselves.
  static set instance(InfoexPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<dynamic> getIE(String url) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

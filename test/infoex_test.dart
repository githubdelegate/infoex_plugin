import 'package:flutter_test/flutter_test.dart';
import 'package:infoex/infoex.dart';
import 'package:infoex/infoex_platform_interface.dart';
import 'package:infoex/infoex_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInfoexPlatform
    with MockPlatformInterfaceMixin
    implements InfoexPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final InfoexPlatform initialPlatform = InfoexPlatform.instance;

  test('$MethodChannelInfoex is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInfoex>());
  });

  test('getPlatformVersion', () async {
    Infoex infoexPlugin = Infoex();
    MockInfoexPlatform fakePlatform = MockInfoexPlatform();
    InfoexPlatform.instance = fakePlatform;

    expect(await infoexPlugin.getPlatformVersion(), '42');
  });
}

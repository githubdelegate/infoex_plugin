import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infoex/infoex_method_channel.dart';

void main() {
  MethodChannelInfoex platform = MethodChannelInfoex();
  const MethodChannel channel = MethodChannel('infoex');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

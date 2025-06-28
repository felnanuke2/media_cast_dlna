import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_cast_dlna/media_cast_dlna_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMediaCastDlna platform = MethodChannelMediaCastDlna();
  const MethodChannel channel = MethodChannel('media_cast_dlna');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

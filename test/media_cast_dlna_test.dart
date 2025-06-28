import 'package:flutter_test/flutter_test.dart';
import 'package:media_cast_dlna/media_cast_dlna_platform_interface.dart';
import 'package:media_cast_dlna/media_cast_dlna_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediaCastDlnaPlatform
    with MockPlatformInterfaceMixin
    implements MediaCastDlnaPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MediaCastDlnaPlatform initialPlatform = MediaCastDlnaPlatform.instance;

  test('$MethodChannelMediaCastDlna is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediaCastDlna>());
  });

  test('getPlatformVersion', () async {
  
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'media_cast_dlna_platform_interface.dart';

/// An implementation of [MediaCastDlnaPlatform] that uses method channels.
class MethodChannelMediaCastDlna extends MediaCastDlnaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_cast_dlna');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

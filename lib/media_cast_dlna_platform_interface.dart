import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_cast_dlna_method_channel.dart';

abstract class MediaCastDlnaPlatform extends PlatformInterface {
  /// Constructs a MediaCastDlnaPlatform.
  MediaCastDlnaPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaCastDlnaPlatform _instance = MethodChannelMediaCastDlna();

  /// The default instance of [MediaCastDlnaPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediaCastDlna].
  static MediaCastDlnaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaCastDlnaPlatform] when
  /// they register themselves.
  static set instance(MediaCastDlnaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

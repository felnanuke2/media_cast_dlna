/// Application constants and configuration
class AppConstants {
  static const String appTitle = 'DLNA Media Cast Demo';

  // Timer intervals
  static const Duration playbackInfoUpdateInterval = Duration(seconds: 1);
  static const Duration deviceConnectivityCheckInterval = Duration(seconds: 5);
  static const Duration discoveryUpdateInterval = Duration(seconds: 5);

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 20.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 8.0;
  static const double thumbnailSize = 80.0;
  static const double iconSize = 48.0;
  static const double playButtonSize = 36.0;
  static const double stopButtonSize = 32.0;

  // Volume settings
  static const int defaultVolume = 50;
  static const int maxVolume = 100;
  static const int volumeDivisions = 20;

  // Error messages
  static const String initializationError = 'Failed to initialize UPnP service';
  static const String playbackError = 'Playback failed';
  static const String volumeError = 'Volume control failed';
  static const String seekError = 'Seek operation failed';
  static const String muteError = 'Mute toggle failed';
  static const String deviceOfflineMessage =
      'Device is offline or unreachable. Please check your network connection.';

  AppConstants._();
}

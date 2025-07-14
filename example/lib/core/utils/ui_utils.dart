import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import '../theme/app_theme.dart';

/// Utility class for UI-related operations
class UiUtils {
  /// Returns the appropriate icon for media type
  static IconData getMediaIcon(String mediaType) {
    if (mediaType.startsWith('video/')) {
      return Icons.videocam;
    } else if (mediaType.startsWith('audio/')) {
      return Icons.music_note;
    } else if (mediaType.startsWith('image/')) {
      return Icons.image;
    } else {
      return Icons.file_present;
    }
  }

  /// Returns the appropriate color for media type
  static Color getMediaColor(String mediaType) {
    if (mediaType.startsWith('video/')) {
      return AppTheme.videoColor;
    } else if (mediaType.startsWith('audio/')) {
      return AppTheme.audioColor;
    } else if (mediaType.startsWith('image/')) {
      return AppTheme.imageColor;
    } else {
      return AppTheme.unknownMediaColor;
    }
  }

  /// Returns the appropriate icon for transport state
  static IconData getTransportStateIcon(TransportState state) {
    switch (state) {
      case TransportState.playing:
        return Icons.play_arrow;
      case TransportState.paused:
        return Icons.pause;
      case TransportState.stopped:
        return Icons.stop;
      case TransportState.transitioning:
        return Icons.sync;
      case TransportState.noMediaPresent:
        return Icons.music_off;
    }
  }

  /// Returns the appropriate color for transport state
  static Color getTransportStateColor(TransportState state) {
    switch (state) {
      case TransportState.playing:
        return AppTheme.playingColor;
      case TransportState.paused:
        return AppTheme.pausedColor;
      case TransportState.stopped:
        return AppTheme.stoppedColor;
      case TransportState.transitioning:
        return AppTheme.transitioningColor;
      case TransportState.noMediaPresent:
        return AppTheme.noMediaColor;
    }
  }

  /// Returns the appropriate text for transport state
  static String getTransportStateText(TransportState state) {
    switch (state) {
      case TransportState.playing:
        return 'Playing';
      case TransportState.paused:
        return 'Paused';
      case TransportState.stopped:
        return 'Stopped';
      case TransportState.transitioning:
        return 'Loading...';
      case TransportState.noMediaPresent:
        return 'No Media';
    }
  }

  /// Shows a snackbar with the given message
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppTheme.onlineColor);
  }

  /// Shows an error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppTheme.offlineColor);
  }

  UiUtils._();
}

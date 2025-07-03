import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import '../core/models/app_models.dart';
import '../core/utils/media_utils.dart';
import '../core/constants/app_constants.dart';

/// Service responsible for managing DLNA media casting operations
class MediaCastService {
  final MediaCastDlnaApi _api;
  Timer? _playbackInfoTimer;
  Timer? _deviceConnectivityTimer;

  MediaCastService() : _api = MediaCastDlnaApi();

  /// Initializes the UPnP service
  Future<void> initialize() async {
    await _api.initializeUpnpService();
  }

  /// Starts monitoring playback information for a device
  void startPlaybackInfoMonitoring({
    required DeviceUdn deviceUdn,
    required VoidCallback onUpdate,
    required Function(PlaybackState) onPlaybackStateChanged,
    required Function(DeviceConnectivityState) onConnectivityChanged,
  }) {
    _playbackInfoTimer?.cancel();
    _playbackInfoTimer = Timer.periodic(
      AppConstants.playbackInfoUpdateInterval,
      (timer) async {
        try {
          final playbackState = await _getPlaybackState(deviceUdn);
          onPlaybackStateChanged(playbackState);
        } catch (e) {
          // Handle playback info error
          onConnectivityChanged(
            const DeviceConnectivityState(isOnline: false),
          );
          timer.cancel();
        }
      },
    );
  }

  /// Starts monitoring device connectivity
  void startDeviceConnectivityMonitoring({
    required DeviceUdn deviceUdn,
    required Function(DeviceConnectivityState) onConnectivityChanged,
  }) {
    _deviceConnectivityTimer?.cancel();
    _deviceConnectivityTimer = Timer.periodic(
      AppConstants.deviceConnectivityCheckInterval,
      (timer) async {
        try {
          final isOnline = await _api.isDeviceOnline(deviceUdn);
          final connectivityState = DeviceConnectivityState(
            isOnline: isOnline,
            lastConnectivityCheck: DateTime.now(),
          );
          onConnectivityChanged(connectivityState);
        } catch (e) {
          onConnectivityChanged(
            DeviceConnectivityState(
              isOnline: false,
              lastConnectivityCheck: DateTime.now(),
            ),
          );
          timer.cancel();
        }
      },
    );
  }

  /// Stops all monitoring timers
  void stopMonitoring() {
    _playbackInfoTimer?.cancel();
    _deviceConnectivityTimer?.cancel();
  }

  /// Gets the current playback state for a device
  Future<PlaybackState> _getPlaybackState(DeviceUdn deviceUdn) async {
    final transportState = await _api.getTransportState(deviceUdn);
    
    int currentPosition = 0;
    if (transportState == TransportState.playing ||
        transportState == TransportState.paused) {
      final timePosition = await _api.getCurrentPosition(deviceUdn);
      currentPosition = timePosition.seconds;
    }

    PlaybackInfo? playbackInfo;
    try {
      playbackInfo = await _api.getPlaybackInfo(deviceUdn);
    } catch (e) {
      // Ignore errors when getting playback info
    }

    VolumeInfo? volumeInfo;
    try {
      volumeInfo = await _api.getVolumeInfo(deviceUdn);
    } catch (e) {
      // Ignore errors when getting volume info
    }

    return PlaybackState(
      currentPosition: currentPosition,
      duration: playbackInfo?.duration.seconds ?? 0,
      currentVolume: volumeInfo?.level.percentage ?? AppConstants.defaultVolume,
      isMuted: volumeInfo?.muteState.isMuted ?? false,
      transportState: transportState,
      currentTrackTitle: MediaUtils.parseTrackTitleFromMetadata(
        playbackInfo?.currentTrackMetadata,
      ),
      currentThumbnailUrl: MediaUtils.getThumbnailUrlFromMetadata(
        playbackInfo?.currentTrackMetadata,
      ),
    );
  }

  /// Plays media on the specified device
  Future<void> playMedia({
    required DeviceUdn deviceUdn,
    required String mediaUrl,
    required MediaMetadata metadata,
  }) async {
    await _api.setMediaUri(deviceUdn, Url(value: mediaUrl), metadata);
    await _api.play(deviceUdn);
  }

  /// Controls playback (play, pause, stop)
  Future<void> controlPlayback({
    required DeviceUdn deviceUdn,
    required String action,
  }) async {
    switch (action) {
      case 'play':
        await _api.play(deviceUdn);
        break;
      case 'pause':
        await _api.pause(deviceUdn);
        break;
      case 'stop':
        await _api.stop(deviceUdn);
        break;
    }
  }

  /// Sets the volume for a device
  Future<void> setVolume({
    required DeviceUdn deviceUdn,
    required int volume,
  }) async {
    await _api.setVolume(deviceUdn, VolumeLevel(percentage: volume));
  }

  /// Seeks to a specific position
  Future<void> seekTo({
    required DeviceUdn deviceUdn,
    required int positionSeconds,
  }) async {
    await _api.seek(deviceUdn, TimePosition(seconds: positionSeconds));
  }

  /// Toggles mute state
  Future<void> toggleMute({
    required DeviceUdn deviceUdn,
    required bool currentMuteState,
  }) async {
    await _api.setMute(deviceUdn, MuteOperation(shouldMute: !currentMuteState));
  }

  /// Disposes the service and cleans up resources
  void dispose() {
    stopMonitoring();
  }
}

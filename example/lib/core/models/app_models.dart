import 'package:media_cast_dlna/media_cast_dlna.dart';

/// Model representing the current playback state
class PlaybackState {
  final int currentPosition;
  final int duration;
  final int currentVolume;
  final bool isMuted;
  final TransportState transportState;
  final String currentTrackTitle;
  final String? currentThumbnailUrl;
  final bool isSliderBeingDragged;

  const PlaybackState({
    this.currentPosition = 0,
    this.duration = 0,
    this.currentVolume = 50,
    this.isMuted = false,
    this.transportState = TransportState.stopped,
    this.currentTrackTitle = '',
    this.currentThumbnailUrl,
    this.isSliderBeingDragged = false,
  });

  PlaybackState copyWith({
    int? currentPosition,
    int? duration,
    int? currentVolume,
    bool? isMuted,
    TransportState? transportState,
    String? currentTrackTitle,
    String? currentThumbnailUrl,
    bool? isSliderBeingDragged,
  }) {
    return PlaybackState(
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      currentVolume: currentVolume ?? this.currentVolume,
      isMuted: isMuted ?? this.isMuted,
      transportState: transportState ?? this.transportState,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      currentThumbnailUrl: currentThumbnailUrl ?? this.currentThumbnailUrl,
      isSliderBeingDragged: isSliderBeingDragged ?? this.isSliderBeingDragged,
    );
  }
}

/// Model representing device connectivity state
class DeviceConnectivityState {
  final bool isOnline;
  final DateTime? lastConnectivityCheck;

  const DeviceConnectivityState({
    this.isOnline = true,
    this.lastConnectivityCheck,
  });

  DeviceConnectivityState copyWith({
    bool? isOnline,
    DateTime? lastConnectivityCheck,
  }) {
    return DeviceConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      lastConnectivityCheck: lastConnectivityCheck ?? this.lastConnectivityCheck,
    );
  }
}

/// Model representing test media items
class TestMediaItem {
  final String title;
  final String url;
  final String type;
  final String description;
  final String? thumbnailUri;
  final String? artist;
  final String? album;
  final String? genre;
  final String? resolution;
  final int? duration;
  final int? trackNumber;
  final int? bitrate;
  final String? date;

  const TestMediaItem({
    required this.title,
    required this.url,
    required this.type,
    required this.description,
    this.thumbnailUri,
    this.artist,
    this.album,
    this.genre,
    this.resolution,
    this.duration,
    this.trackNumber,
    this.bitrate,
    this.date,
  });

  MediaMetadata toMediaMetadata() {
    if (type.startsWith('video/')) {
      return VideoMetadata(
        title: title,
        description: description,
        upnpClass: 'object.item.videoItem.movie',
        thumbnailUri: thumbnailUri != null ? Url(value: thumbnailUri!) : null,
        duration: duration != null ? TimeDuration(seconds: duration!) : null,
        genre: genre,
        resolution: resolution,
        bitrate: bitrate,
      );
    } else if (type.startsWith('audio/')) {
      return AudioMetadata(
        title: title,
        artist: artist ?? 'Unknown Artist',
        album: album ?? 'Unknown Album',
        description: description,
        upnpClass: 'object.item.audioItem.musicTrack',
        albumArtUri: thumbnailUri != null ? Url(value: thumbnailUri!) : null,
        genre: genre,
        duration: duration != null ? TimeDuration(seconds: duration!) : null,
        originalTrackNumber: trackNumber,
      );
    } else if (type.startsWith('image/')) {
      return ImageMetadata(
        title: title,
        description: description,
        upnpClass: 'object.item.imageItem.photo',
        resolution: resolution,
        thumbnailUri: thumbnailUri != null ? Url(value: thumbnailUri!) : null,
        date: date,
      );
    } else {
      return AudioMetadata(
        title: title,
        artist: 'Unknown',
        album: 'Unknown',
        description: description,
        upnpClass: 'object.item',
      );
    }
  }
}

import 'package:media_cast_dlna/media_cast_dlna.dart';

/// Utility class for media-related operations
class MediaUtils {
  static String parseTrackTitleFromMetadata(MediaMetadata? metadata) {
    if (metadata == null) return '';

    switch (metadata) {
      case AudioMetadata audioMetadata:
        return audioMetadata.title ?? audioMetadata.album ?? 'Unknown Audio';
      case VideoMetadata videoMetadata:
        return videoMetadata.title ?? 'Unknown Video';
      case ImageMetadata imageMetadata:
        return imageMetadata.title ?? 'Unknown Image';
    }
  }

  static String? getThumbnailUrlFromMetadata(MediaMetadata? metadata) {
    if (metadata == null) return null;

    switch (metadata) {
      case AudioMetadata audioMetadata:
        return audioMetadata.albumArtUri?.value;
      case VideoMetadata videoMetadata:
        return videoMetadata.thumbnailUri?.value;
      case ImageMetadata imageMetadata:
        return imageMetadata.thumbnailUri?.value;
    }
  }

  static MediaMetadata createCustomMediaMetadata({
    required String title,
    required String url,
  }) {
    return AudioMetadata(
      title: title,
      artist: 'Unknown',
      album: 'Unknown',
      description: 'Custom Media',
      upnpClass: 'object.item',
    );
  }

  MediaUtils._();
}

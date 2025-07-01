# DLNA/UPnP Closed Captions & Subtitle Support Guide

## Overview

**Yes, UPnP/DLNA does support closed captions and subtitles!** This guide explains how subtitle support works in DLNA/UPnP and what has been added to this plugin.

## UPnP/DLNA Subtitle Standards

### Supported Subtitle Formats

DLNA/UPnP supports several subtitle formats:

1. **SubRip Text (.srt)** - Most common format
   ```
   MIME Type: text/srt
   Example: movie_en.srt
   ```

2. **WebVTT (.vtt)** - Web Video Text Tracks
   ```
   MIME Type: text/vtt
   Example: movie_en.vtt
   ```

3. **MicroDVD (.sub)** - Frame-based subtitles
   ```
   MIME Type: text/sub
   Example: movie_en.sub
   ```

4. **Advanced SubStation Alpha (.ass/.ssa)** - Advanced formatting
   ```
   MIME Type: text/ass or text/ssa
   Example: movie_en.ass
   ```

### Implementation Approaches

#### 1. External Subtitle Files (Recommended)
- Separate subtitle files linked to video content
- Multiple language support
- Easy to add/remove subtitle tracks
- Better compatibility across devices

#### 2. Embedded Subtitles
- Subtitles embedded within video files (MKV, MP4)
- Requires device support for subtitle extraction
- Limited control over subtitle selection

## Current Implementation Status

### ✅ What's Added

1. **Data Structures**:
   ```dart
   class SubtitleTrack {
     final String id;           // Unique track identifier
     final String uri;          // Subtitle file URL
     final String mimeType;     // text/srt, text/vtt, etc.
     final String language;     // ISO 639-1 language code
     final String? title;       // Human-readable title
     final bool? isDefault;     // Default track flag
   }
   ```

2. **API Methods**:
   ```dart
   // Set media with subtitle tracks
   Future<void> setMediaUriWithSubtitles(
     String deviceUdn, 
     String uri, 
     MediaMetadata metadata,
     List<SubtitleTrack> subtitleTracks
   );

   // Control subtitle tracks
   Future<void> setSubtitleTrack(String deviceUdn, String? subtitleTrackId);
   List<SubtitleTrack> getAvailableSubtitleTracks(String deviceUdn);
   SubtitleTrack? getCurrentSubtitleTrack(String deviceUdn);
   ```

3. **DIDL-Lite Metadata Enhancement**:
   - Multiple resource elements for subtitle tracks
   - Proper MIME type declarations
   - Language metadata support

### 🚧 What Needs Implementation

1. **Android Native Implementation** (Kotlin):
   ```kotlin
   // Implement in MediaCastDlnaPlugin.kt
   override fun setMediaUriWithSubtitles(
       deviceUdn: String,
       uri: String, 
       metadata: MediaMetadata,
       subtitleTracks: List<SubtitleTrack>,
       callback: (Result<Unit>) -> Unit
   ) {
       // Implementation needed
   }
   ```

2. **iOS Native Implementation** (Swift):
   ```swift
   // Implement in MediaCastDlnaPlugin.swift
   func setMediaUriWithSubtitles(
       deviceUdn: String,
       uri: String,
       metadata: MediaMetadata,
       subtitleTracks: [SubtitleTrack],
       completion: @escaping (Result<Void, Error>) -> Void
   ) {
       // Implementation needed
   }
   ```

## Usage Examples

### Basic Video with Subtitles

```dart
// Define subtitle tracks
final subtitleTracks = [
  SubtitleTrack(
    id: 'en_srt',
    uri: 'https://example.com/movie_en.srt',
    mimeType: 'text/srt',
    language: 'en',
    title: 'English',
    isDefault: true,
  ),
  SubtitleTrack(
    id: 'es_srt',
    uri: 'https://example.com/movie_es.srt',
    mimeType: 'text/srt',
    language: 'es',
    title: 'Spanish',
    isDefault: false,
  ),
];

// Play video with subtitles
await controller.setMediaUriWithSubtitles(
  device.udn,
  'https://example.com/movie.mp4',
  videoMetadata,
  subtitleTracks,
);

await controller.play(device.udn);
```

### Subtitle Track Control

```dart
// Get available subtitle tracks
final tracks = await controller.getAvailableSubtitleTracks(device.udn);

// Switch to Spanish subtitles
await controller.setSubtitleTrack(device.udn, 'es_srt');

// Disable subtitles
await controller.setSubtitleTrack(device.udn, null);

// Get current subtitle track
final current = await controller.getCurrentSubtitleTrack(device.udn);
```

## DIDL-Lite XML Example

Here's how subtitle information is represented in DIDL-Lite metadata:

```xml
<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"
           xmlns:dc="http://purl.org/dc/elements/1.1/"
           xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
  <item id="video001" parentID="0" restricted="1">
    <dc:title>Big Buck Bunny</dc:title>
    <dc:creator>Blender Foundation</dc:creator>
    <upnp:class>object.item.videoItem.movie</upnp:class>
    
    <!-- Main video resource -->
    <res protocolInfo="http-get:*:video/mp4:*" 
         duration="00:09:56.000"
         resolution="1280x720">
      https://example.com/bigbuckbunny.mp4
    </res>
    
    <!-- English subtitle resource -->
    <res protocolInfo="http-get:*:text/srt:*">
      https://example.com/bigbuckbunny_en.srt
    </res>
    
    <!-- Spanish subtitle resource -->
    <res protocolInfo="http-get:*:text/srt:*">
      https://example.com/bigbuckbunny_es.srt
    </res>
    
    <!-- French WebVTT subtitle resource -->
    <res protocolInfo="http-get:*:text/vtt:*">
      https://example.com/bigbuckbunny_fr.vtt
    </res>
  </item>
</DIDL-Lite>
```

## Device Compatibility

### DLNA Renderer Support
- **Smart TVs**: Most modern smart TVs support external subtitles
- **Media Players**: VLC, Kodi, Plex players typically support subtitles
- **Set-top Boxes**: Android TV, Apple TV, Roku with DLNA apps
- **Game Consoles**: PlayStation, Xbox with media apps

### Testing Subtitle Support
```dart
// Check if device supports subtitle actions
bool hasSubtitleSupport = await controller.hasService(
  device.udn, 
  'urn:schemas-upnp-org:service:AVTransport:1'
);

// Test subtitle functionality
try {
  await controller.setSubtitleTrack(device.udn, 'test_track');
  print('Device supports subtitle control');
} catch (e) {
  print('Device may not support subtitle control: $e');
}
```

## Best Practices

### 1. Subtitle File Hosting
```dart
// Ensure subtitle files are accessible via HTTP/HTTPS
final subtitleUri = 'https://your-server.com/subtitles/movie_en.srt';

// Use proper Content-Type headers
// Content-Type: text/srt; charset=utf-8
```

### 2. Language Codes
```dart
// Use ISO 639-1 language codes
final languages = {
  'en': 'English',
  'es': 'Spanish', 
  'fr': 'French',
  'de': 'German',
  'it': 'Italian',
  'pt': 'Portuguese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'zh': 'Chinese',
};
```

### 3. Fallback Strategy
```dart
// Always provide fallback when subtitles fail
try {
  await controller.setMediaUriWithSubtitles(deviceUdn, uri, metadata, subtitles);
} catch (e) {
  // Fallback to playing without subtitles
  await controller.setMediaUri(deviceUdn, uri, metadata);
}
```

### 4. Subtitle File Validation
```dart
class SubtitleValidator {
  static bool isValidSubtitleUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final supportedExtensions = ['srt', 'vtt', 'sub', 'ass', 'ssa'];
    final extension = url.split('.').last.toLowerCase();
    
    return supportedExtensions.contains(extension);
  }
  
  static String getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'srt': return 'text/srt';
      case 'vtt': return 'text/vtt';
      case 'sub': return 'text/sub';
      case 'ass':
      case 'ssa': return 'text/ass';
      default: return 'text/plain';
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Subtitles not appearing**:
   - Verify subtitle file is accessible via HTTP
   - Check MIME type is correctly set
   - Ensure device supports the subtitle format

2. **Subtitle synchronization issues**:
   - Verify subtitle timing matches video
   - Check for encoding issues (use UTF-8)
   - Some devices may have delays

3. **Multiple language issues**:
   - Ensure language codes are correct (ISO 639-1)
   - Check if device supports multiple subtitle tracks
   - Some devices may only support one active track

4. **UnsupportedOperationException: Device does not support subtitle track control**:
   - This error occurs when the DLNA device doesn't support subtitle control actions
   - Many older DLNA devices and some smart TVs don't support dynamic subtitle switching
   - **Solution**: Check device capabilities before using subtitle controls
   - **Workaround**: Include subtitles in the initial media metadata instead of trying to control them dynamically

5. **Subtitle tracks not switching**:
   - Device may not support the `SetCurrentSubtitle` UPnP action
   - Some devices require subtitles to be embedded in the media file
   - **Solution**: Use the enhanced subtitle support checking in the latest version

### Debug Information
```dart
// Enable debug logging
Logger.level = LogLevel.debug;

// Check subtitle support
final services = await controller.getDeviceServices(device.udn);
final hasAVTransport = services.any((s) => s.serviceType.contains('AVTransport'));

print('Device supports AVTransport: $hasAVTransport');
```

## Implementation Roadmap

### Phase 1: Core Implementation ✅
- [x] Data structures defined
- [x] API methods specified
- [x] DIDL-Lite enhancement
- [x] Pigeon code generation

### Phase 2: Native Implementation 🚧
- [ ] Android Kotlin implementation
- [ ] iOS Swift implementation
- [ ] Error handling and validation
- [ ] Device capability detection

### Phase 3: Advanced Features 📋
- [ ] Subtitle style customization
- [ ] Subtitle track switching during playback
- [ ] Automatic subtitle detection
- [ ] Subtitle caching and optimization

## Resources

- [UPnP AV Architecture Specification](https://openconnectivity.org/developer/specifications/upnp-resources/upnp/)
- [DLNA Guidelines](https://spirespark.com/dlna/guidelines/)
- [WebVTT Specification](https://w3c.github.io/webvtt/)
- [SubRip Text Format](https://en.wikipedia.org/wiki/SubRip)

---

**Note**: This implementation provides the foundation for subtitle support in DLNA/UPnP. The native platform implementations (Android/iOS) need to be completed to enable full functionality.

### 5. Device Capability Checking
```dart
// Check if device supports subtitle control before using subtitle features
bool supportsSubtitles = await checkDeviceSubtitleSupport(device.udn);

if (supportsSubtitles) {
  // Device supports subtitle control - show subtitle controls in UI
  try {
    await controller.setSubtitleTrack(device.udn, 'en_srt');
  } catch (e) {
    print('Failed to set subtitle track: $e');
  }
} else {
  // Device doesn't support subtitle control - hide subtitle controls
  print('Device does not support subtitle track control');
  // You can still include subtitles in the metadata when setting media URI
}

// Gracefully handle UnsupportedOperationException
try {
  await controller.setSubtitleTrack(device.udn, subtitleTrackId);
} on UnsupportedOperationException {
  // Device doesn't support subtitle control
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('This device does not support subtitle control')),
  );
} catch (e) {
  // Other errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error setting subtitle: $e')),
  );
}
```

### 6. Error Handling Patterns
```dart
class SubtitleErrorHandler {
  static String getErrorMessage(Exception e) {
    if (e is UnsupportedOperationException) {
      return 'Device does not support subtitle control';
    } else if (e.toString().contains('timeout')) {
      return 'Subtitle operation timed out';
    } else {
      return 'Failed to control subtitles: ${e.toString()}';
    }
  }
  
  static bool shouldShowSubtitleControls(DlnaDevice device) {
    // Check device capabilities or previous error history
    return device.hasService('AVTransport') && 
           !_knownNonSubtitleDevices.contains(device.udn);
  }
}
```

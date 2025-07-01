# Subtitle Display Troubleshooting Guide

## 🚨 Common Reasons Why Subtitles Don't Display

### 1. **Device Doesn't Support Subtitle Control**
```
Error: UnsupportedOperationException: Device does not support subtitle track control
```
**Solution**: Your device doesn't support dynamic subtitle switching, but might still support subtitles in metadata.

### 2. **Device Doesn't Support External Subtitles**
Many DLNA devices only support:
- Embedded subtitles (burned into video)
- Subtitles embedded in container files (MKV, MP4 with subtitle tracks)

### 3. **Subtitle URL Issues**
- **HTTPS vs HTTP**: Some devices only support HTTP URLs
- **CORS Issues**: Subtitle server must allow cross-origin requests
- **File Format**: Device might not support the subtitle format (SRT, VTT, etc.)

### 4. **Subtitle File Format Issues**
- **Encoding**: Must be UTF-8 encoded
- **Line Endings**: Should use Windows line endings (\r\n)
- **BOM**: Some devices require UTF-8 BOM, others reject it

## 🔧 Debugging Steps

### Step 1: Check Device Capabilities
```dart
// Run the SubtitleDebugExample to check your device capabilities
// Look for these indicators:
// - supportsSubtitleControl: true/false
// - hasSetCurrentSubtitle: true/false
// - availableActions: list of UPnP actions
```

### Step 2: Test Basic Subtitle URL
```dart
// Test with a simple, known-working subtitle file
final testSubtitle = SubtitleTrack(
  id: 'test',
  uri: 'http://your-local-server/test.srt', // Use HTTP, not HTTPS
  mimeType: 'text/srt',
  language: 'en',
  title: 'Test',
);
```

### Step 3: Check Subtitle File Format
```srt
1
00:00:01,000 --> 00:00:04,000
This is a test subtitle

2
00:00:05,000 --> 00:00:08,000
With proper formatting
```

### Step 4: Verify Network Access
- Ensure subtitle URL is accessible from your device's network
- Test the URL in a browser on the same network
- Check for firewall/router issues

## 🎯 Device-Specific Solutions

### Smart TVs
- **Samsung**: Often requires subtitles to be on the same server as video
- **LG**: May need specific DLNA profiles
- **Sony**: Usually supports external subtitles well

### Media Players
- **VLC**: Excellent subtitle support
- **Kodi**: Good external subtitle support
- **Plex**: Handles subtitles well

### Android TV Boxes
- Usually good subtitle support
- May require specific formats

## 💡 Workarounds

### Option 1: Server-Side Subtitle Embedding
Host video and subtitles on the same server:
```
http://your-server/video.mp4
http://your-server/video.srt  // Same filename
```

### Option 2: Use Subtitle-Enabled Video Formats
Convert video to MKV with embedded subtitles:
```bash
ffmpeg -i video.mp4 -i subtitles.srt -c copy -c:s srt output.mkv
```

### Option 3: Local HTTP Server
Run a local server for subtitle files:
```dart
// Example using shelf package
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void startSubtitleServer() async {
  final handler = createStaticHandler('path/to/subtitle/files');
  final server = await serve(handler, 'localhost', 8080);
  print('Subtitle server running on http://localhost:8080');
}
```

### Option 4: Subtitle Proxy Service
Create a service that converts subtitle formats on-the-fly.

## 🧪 Testing Checklist

- [ ] Device supports AVTransport service
- [ ] Subtitle file is accessible via HTTP
- [ ] Subtitle file is properly formatted
- [ ] Subtitle MIME type is correct
- [ ] No CORS issues
- [ ] Device is on same network as subtitle server
- [ ] Test with known-working subtitle files
- [ ] Try different subtitle formats (SRT, VTT)
- [ ] Test with embedded subtitles

## 📱 Code Examples

### Test Basic Playback (No Subtitles)
```dart
// First test without subtitles
await controller.setMediaUri(device.udn, videoUrl, metadata);
await controller.play(device.udn);
```

### Test with Local Subtitle Server
```dart
// Start local server
final server = await HttpServer.bind('localhost', 8080);
server.listen((request) async {
  final file = File('subtitle.srt');
  final contents = await file.readAsString();
  request.response
    ..headers.contentType = ContentType('text', 'srt')
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(contents)
    ..close();
});

// Use local URL
final subtitle = SubtitleTrack(
  id: 'local',
  uri: 'http://localhost:8080/subtitle.srt',
  mimeType: 'text/srt',
  language: 'en',
  title: 'Local Test',
);
```

### Debug Metadata Generation
```dart
// Enable detailed logging
await controller.setMediaUriWithSubtitles(
  device.udn, 
  videoUrl, 
  metadata, 
  subtitles
);

// Check Android logs for metadata details:
// adb logcat | grep MediaCastDlna
```

## 📞 Getting Help

If subtitles still don't work:

1. **Check device documentation** for subtitle support
2. **Test with other DLNA apps** (BubbleUPnP, AllCast, etc.)
3. **Try different subtitle formats** (SRT → VTT → SUB)
4. **Use embedded subtitles** in video files
5. **Contact device manufacturer** about subtitle support

## 🎬 Alternative Solutions

If your device doesn't support external subtitles:

1. **Use video players with subtitle support** (VLC, Kodi)
2. **Embed subtitles in video files** before casting
3. **Use screen mirroring** instead of DLNA
4. **Upgrade to a device with better subtitle support**

Remember: DLNA subtitle support varies greatly between devices. Not all devices support external subtitles, and this is a limitation of the device, not the plugin.

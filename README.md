# media_cast_dlna

A Flutter plugin for discovering and controlling DLNA/UPnP media devices on the local network. This plugin allows you to:

- Discover DLNA/UPnP devices (Media Renderers and Media Servers)
- Browse and search media content on Media Servers
- Control media playback on Media Renderers (play, pause, stop, seek)
- Control volume and receive real-time playback events

## Features

### Device Discovery
- Automatic discovery of UPnP/DLNA devices on the local network
- Support for both Media Renderers (players) and Media Servers (content providers)
- Real-time device addition/removal notifications

### Media Server Support
- Browse content directories
- Search media content
- Support for audio, video, and image content

### Media Renderer Control
- Play media from URLs or Media Servers
- Full transport control (play, pause, stop, seek, next, previous)
- Volume control and mute/unmute
- Real-time playback state updates

### Event Support
- Device discovery events
- Transport state changes
- Position updates during playback
- Volume changes
- Track changes

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅ (using jUPnP) |
| iOS      | ✅ (using CocoaUPnP) |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  media_cast_dlna: ^0.0.1
```

## Usage

### Basic Setup

```dart
import 'package:media_cast_dlna/media_cast_dlna.dart';

class MyDlnaApp extends StatefulWidget {
  @override
  _MyDlnaAppState createState() => _MyDlnaAppState();
}

class _MyDlnaAppState extends State<MyDlnaApp> {
  late MediaCastDlnaController _dlnaController;
  List<DlnaDevice> _devices = [];
  
  @override
  void initState() {
    super.initState();
    _dlnaController = MediaCastDlnaController.instance;
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _dlnaController.onDeviceDiscovered.listen((device) {
      setState(() {
        _devices.add(device);
      });
    });

    _dlnaController.onDeviceRemoved.listen((deviceUdn) {
      setState(() {
        _devices.removeWhere((device) => device.udn == deviceUdn);
      });
    });
  }
}
```

### Device Discovery

```dart
// Start discovering devices
await _dlnaController.startDiscovery(timeoutSeconds: 10);

// Get discovered devices
List<DlnaDevice> devices = await _dlnaController.getDiscoveredDevices();

// Get only media renderers
List<DlnaDevice> renderers = await _dlnaController.getMediaRenderers();

// Get only media servers
List<DlnaDevice> servers = await _dlnaController.getMediaServers();

// Stop discovery
await _dlnaController.stopDiscovery();
```

### Media Playback Control

```dart
String rendererUdn = "uuid:your-renderer-device-id";

// Play media from URL
await _dlnaController.playMedia(
  rendererUdn,
  'http://example.com/video.mp4',
  metadata: '''<?xml version="1.0"?>
<DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/">
  <item id="1" parentID="0" restricted="1">
    <dc:title>My Video</dc:title>
    <upnp:class>object.item.videoItem</upnp:class>
    <res protocolInfo="http-get:*:video/mp4:*">http://example.com/video.mp4</res>
  </item>
</DIDL-Lite>''',
);

// Control playback
await _dlnaController.play(rendererUdn);
await _dlnaController.pause(rendererUdn);
await _dlnaController.stop(rendererUdn);

// Seek to 60 seconds
await _dlnaController.seek(rendererUdn, Duration(seconds: 60));

// Volume control
await _dlnaController.setVolume(rendererUdn, 50); // 50%
await _dlnaController.setMute(rendererUdn, true);

// Get playback info
PlaybackInfo info = await _dlnaController.getPlaybackInfo(rendererUdn);
print('State: ${info.state}, Position: ${info.position}s');
```

### Browse Media Server Content

```dart
String serverUdn = "uuid:your-media-server-id";

// Browse root directory
List<MediaItem> rootItems = await _dlnaController.browseContent(
  serverUdn,
  parentId: "0", // Root container
);

// Browse specific container
List<MediaItem> containerItems = await _dlnaController.browseContent(
  serverUdn,
  parentId: "1", // Some container ID
  startIndex: 0,
  count: 50,
);

// Search for content
List<MediaItem> searchResults = await _dlnaController.searchContent(
  serverUdn,
  'dc:title contains "music"',
  startIndex: 0,
  count: 100,
);
```

### Event Handling

```dart
// Listen to transport state changes
_dlnaController.onTransportStateChanged.listen((event) {
  print('Device ${event.deviceUdn} state: ${event.state}');
});

// Listen to position changes
_dlnaController.onPositionChanged.listen((event) {
  print('Device ${event.deviceUdn} position: ${event.positionSeconds}s');
});

// Listen to volume changes
_dlnaController.onVolumeChanged.listen((event) {
  print('Device ${event.deviceUdn} volume: ${event.volumeInfo.volume}%');
});

// Subscribe to events for a specific device
await _dlnaController.subscribeToRendererEvents(rendererUdn);
```

## Requirements

- Flutter 3.3.0 or higher
- Dart 3.0 or higher
- Android API level 21+ (for Android)
- iOS 12.0+ (for iOS)

## Example App

The example app demonstrates:
- Device discovery and listing
- Media renderer selection
- Playback control
- Real-time status updates

Run the example:
```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.


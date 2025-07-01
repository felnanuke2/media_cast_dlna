# 📺 Media Cast DLNA

<div align="center">

[![Pub Version](https://img.shields.io/pub/v/media_cast_dlna?style=for-the-badge)](https://pub.dev/packages/media_cast_dlna)
[![Platform](https://img.shields.io/badge/platform-Android-brightgreen?style=for-the-badge)](https://github.com/felnanuke2/media_cast_dlna)
[![Flutter](https://img.shields.io/badge/Flutter-3.3.0+-blue?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-purple?style=for-the-badge)](LICENSE)

**A powerful Flutter plugin for discovering and controlling DLNA/UPnP media devices on your local network**

*Cast your media to smart TVs, speakers, and other DLNA-enabled devices with ease!*

</div>

---

## 📦 Installation

### Step 1: Add to pubspec.yaml

```yaml
dependencies:
  media_cast_dlna: ^0.0.1
```

### Step 2: Install the package

```bash
flutter pub get
```

### Step 3: Android Configuration

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Required for DLNA/UPnP network discovery and communication -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
    
    <application
        android:label="your_app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Your existing activity configuration -->
        
        <!-- Required service for JUPnP Android UPnP functionality -->
        <service android:name="org.jupnp.android.AndroidUpnpServiceImpl"/>
    </application>
</manifest>
```

### Step 4: Import and Initialize

```dart
import 'package:media_cast_dlna/media_cast_dlna.dart';
```

## 🚀 What is Media Cast DLNA?

Media Cast DLNA is a comprehensive Flutter plugin that transforms your app into a media casting powerhouse. Built with cutting-edge technology using the **Pigeon package** for seamless native interface generation, this plugin provides robust DLNA/UPnP functionality for discovering and controlling media devices on your local network.

### 🎯 Key Capabilities

- **🔍 Smart Device Discovery**: Automatically find DLNA/UPnP devices (TVs, speakers, media players)
- **📱 Media Renderer Control**: Full playback control with play, pause, stop, seek, volume management
- **📂 Media Server Integration**: Browse and search content from DLNA media servers
- **🎬 Advanced Subtitle Support**: Handle subtitle tracks for enhanced viewing experience
- **⚡ Real-time Events**: Get instant updates on playback state, position, and volume changes
- **🔧 Native Performance**: Powered by Pigeon-generated native interfaces for optimal performance

## 🏠 Unlocking Your Home Network: A Look at DLNA-Enabled TVs, Speakers, and Media Devices

In the interconnected home of today, the ability to seamlessly share and stream digital content is paramount. One of the key technologies facilitating this is the Digital Living Network Alliance (DLNA), a set of standards that allows compliant devices to discover, share, and play media files over a home network. For consumers, this translates to the effortless enjoyment of photos, music, and videos stored on a computer or network-attached storage (NAS) drive on a variety of entertainment devices.

Numerous manufacturers across the consumer electronics spectrum have embraced DLNA certification, ensuring a wide array of interoperable products.

### 📺 Leading the Pack: DLNA-Compatible Television Manufacturers

Many of the world's leading television manufacturers have integrated DLNA technology into their smart TVs. This enables users to easily stream their personal media libraries directly to the biggest screen in the house. Prominent brands offering DLNA-certified TVs include:

* **Samsung:** A long-time supporter of DLNA, many of Samsung's smart TVs feature robust DLNA capabilities.
* **LG:** Another major player, LG's webOS smart TVs typically come equipped with DLNA support.
* **Sony:** Sony's Bravia line of televisions has a history of DLNA integration, allowing for easy streaming from other Sony and third-party devices.
* **Panasonic:** Viera TVs from Panasonic often include DLNA functionality, fitting into a broader ecosystem of connected devices.
* **Hisense and TCL:** These rapidly growing brands also offer a range of smart TVs with DLNA support, providing more budget-friendly options for consumers.
* **Philips:** Many of Philips' smart TVs are DLNA-certified, allowing them to communicate with other compliant devices.

### 🔊 The Sound of Connectivity: DLNA in the Audio Realm

The convenience of DLNA extends beyond visual media, with a growing number of speaker and audio device manufacturers incorporating the standard. This allows for the creation of multi-room audio systems and easy streaming of high-fidelity music files. Key players in this space include:

* **Bose:** Known for its premium audio products, Bose offers a selection of smart speakers and soundbars with DLNA compatibility.
* **Sonos:** While primarily known for its proprietary wireless mesh network, many Sonos products also support DLNA for broader compatibility.
* **Denon and Marantz:** These sister companies, renowned for their AV receivers and audio components, widely support DLNA across their product lines.
* **Yamaha:** A major name in both musical instruments and home audio, Yamaha's MusicCast system and other networked audio products frequently feature DLNA.
* **Harman Kardon:** This brand offers a range of speakers and audio systems that include DLNA as a connectivity option.
* **Bluesound:** Focused on high-resolution audio, Bluesound's wireless speakers and components are DLNA-certified, catering to audiophiles.

### 🎮 The Hubs of Your Media: DLNA-Enabled Media Renderers and Servers

Beyond the end-point devices like TVs and speakers, a crucial part of the DLNA ecosystem is the "media renderer" and "media server." A media renderer is a device that can play content it receives from a media server. While many smart TVs and speakers act as renderers, dedicated devices also exist.

**Media Servers** are the backbone of a DLNA setup, storing and serving the media files. These can be:

* **Computers:** Both Windows and macOS have built-in DLNA server capabilities (often referred to as media streaming).
* **Network-Attached Storage (NAS) Drives:** Brands like **Synology**, **QNAP**, and **Western Digital** offer NAS devices with powerful DLNA server software, providing a centralized and always-on media library.

**Dedicated Media Renderers** and players also play a significant role:

* **Gaming Consoles:** Sony's **PlayStation** and Microsoft's **Xbox** consoles have long supported DLNA, acting as powerful media renderers for TVs.
* **Streaming Media Players:** While many popular streaming sticks and boxes prioritize their own ecosystems, some, like certain models from **Roku** and **Amazon Fire TV** (with third-party apps), can function as DLNA clients.
* **Software Media Players:** Applications like **Plex**, **Kodi**, and **VLC Media Player** can act as both DLNA servers and renderers on a variety of devices, offering a high degree of customization and flexibility.

The prevalence of DLNA certification across a wide range of manufacturers ensures that consumers can build a connected home entertainment system with a high degree of confidence in device interoperability. By looking for the DLNA logo, users can unlock the full potential of their home network and enjoy their digital media library on their terms.

## 🏗️ Architecture & Technology

This plugin leverages the power of **Pigeon** - Google's code generation tool that creates type-safe communication between Dart and native platforms. This ensures:

✅ **Type Safety**: No more runtime errors from incorrect method calls  
✅ **Performance**: Direct native method invocation without JSON serialization overhead  
✅ **Maintainability**: Auto-generated code reduces bugs and simplifies updates  
✅ **Consistency**: Identical APIs across platforms  

### Native Libraries Used:
- **Android**: jUPnP (Java UPnP library)
- **iOS**: UPnAtom *(Coming Soon)*

## 📱 Platform Support

| Platform | Status | Version |
|----------|--------|---------|
| 🤖 **Android** | ✅ **Available** | API 21+ |
| 🍎 **iOS** | 🚧 **Coming Soon** | iOS 12.0+ |

> **Note**: iOS support is currently in development and will be released in the next major update. Stay tuned!

## 🎮 Quick Start Guide

### 1. Initialize the Plugin

```dart
import 'package:media_cast_dlna/media_cast_dlna.dart';

class MediaCastApp extends StatefulWidget {
  @override
  _MediaCastAppState createState() => _MediaCastAppState();
}

class _MediaCastAppState extends State<MediaCastApp> {
  final _mediaCast = MediaCastDlna();
  List<DlnaDevice> _discoveredDevices = [];
  DlnaDevice? _selectedRenderer;
  
  @override
  void initState() {
    super.initState();
    _initializeMediaCast();
  }

  Future<void> _initializeMediaCast() async {
    try {
      // Initialize the UPnP service
      await _mediaCast.initializeUpnpService();
      
      // Check if service is ready
      bool isReady = await _mediaCast.isUpnpServiceInitialized();
      print('UPnP Service Ready: $isReady');
      
    } catch (e) {
      print('Failed to initialize: $e');
    }
  }
}
```

### 2. Discover DLNA Devices

```dart
Future<void> _startDeviceDiscovery() async {
  try {
    // Start discovery with timeout
    await _mediaCast.startDiscovery(
      DiscoveryOptions(timeoutSeconds: 10)
    );
    
    // Periodically check for discovered devices
    Timer.periodic(Duration(seconds: 2), (timer) async {
      final devices = await _mediaCast.getDiscoveredDevices();
      setState(() {
        _discoveredDevices = devices;
      });
      
      // Stop timer after 30 seconds
      if (timer.tick >= 15) {
        timer.cancel();
        await _mediaCast.stopDiscovery();
      }
    });
    
  } catch (e) {
    print('Discovery failed: $e');
  }
}

// Get only media renderers (devices that can play content)
List<DlnaDevice> getMediaRenderers() {
  return _discoveredDevices
      .where((device) => device.deviceType.contains('MediaRenderer'))
      .toList();
}

// Get only media servers (devices that provide content)
List<DlnaDevice> getMediaServers() {
  return _discoveredDevices
      .where((device) => device.deviceType.contains('MediaServer'))
      .toList();
}
```

### 3. Cast Media to a Device

```dart
Future<void> _castMedia(DlnaDevice renderer, String mediaUrl) async {
  try {
    // Create media metadata
    final metadata = MediaMetadata(
      title: 'My Awesome Video',
      artist: 'Content Creator',
      duration: 7200, // 2 hours in seconds
      mimeType: 'video/mp4',
    );
    
    // Set the media URI on the renderer
    await _mediaCast.setMediaUri(
      renderer.udn,
      mediaUrl,
      metadata,
    );
    
    // Start playback
    await _mediaCast.play(renderer.udn);
    
    print('✅ Media cast successfully!');
    
  } catch (e) {
    print('❌ Failed to cast media: $e');
  }
}
```

### 4. Control Playback

```dart
class PlaybackController {
  final MediaCastDlna _mediaCast;
  final String _deviceUdn;
  
  PlaybackController(this._mediaCast, this._deviceUdn);
  
  // Basic controls
  Future<void> play() => _mediaCast.play(_deviceUdn);
  Future<void> pause() => _mediaCast.pause(_deviceUdn);
  Future<void> stop() => _mediaCast.stop(_deviceUdn);
  
  // Navigation
  Future<void> skipNext() => _mediaCast.next(_deviceUdn);
  Future<void> skipPrevious() => _mediaCast.previous(_deviceUdn);
  
  // Seek to specific position (in seconds)
  Future<void> seekTo(int seconds) => _mediaCast.seek(_deviceUdn, seconds);
  
  // Volume control
  Future<void> setVolume(int volume) => _mediaCast.setVolume(_deviceUdn, volume);
  Future<void> toggleMute() async {
    final volumeInfo = await _mediaCast.getVolumeInfo(_deviceUdn);
    await _mediaCast.setMute(_deviceUdn, !volumeInfo.muted);
  }
  
  // Get current status
  Future<PlaybackInfo> getStatus() => _mediaCast.getPlaybackInfo(_deviceUdn);
  Future<int> getCurrentPosition() => _mediaCast.getCurrentPosition(_deviceUdn);
  Future<TransportState> getTransportState() => _mediaCast.getTransportState(_deviceUdn);
}
```

## 🎬 Advanced Features

### Subtitle Support

```dart
// Cast media with subtitle tracks
Future<void> _castWithSubtitles(DlnaDevice renderer, String mediaUrl) async {
  final subtitleTracks = [
    SubtitleTrack(
      id: 'sub1',
      language: 'en',
      label: 'English',
      uri: 'https://example.com/subtitles/english.srt',
      mimeType: 'text/srt',
    ),
    SubtitleTrack(
      id: 'sub2', 
      language: 'es',
      label: 'Español',
      uri: 'https://example.com/subtitles/spanish.srt',
      mimeType: 'text/srt',
    ),
  ];
  
  final metadata = MediaMetadata(
    title: 'Movie with Subtitles',
    mimeType: 'video/mp4',
  );
  
  await _mediaCast.setMediaUriWithSubtitles(
    renderer.udn,
    mediaUrl,
    metadata,
    subtitleTracks,
  );
}

// Control subtitle tracks
Future<void> _manageSubtitles(String deviceUdn) async {
  // Check if device supports subtitle control
  bool supportsSubtitles = await _mediaCast.supportsSubtitleControl(deviceUdn);
  
  if (supportsSubtitles) {
    // Get available subtitle tracks
    List<SubtitleTrack> tracks = await _mediaCast.getAvailableSubtitleTracks(deviceUdn);
    
    // Get current subtitle track
    SubtitleTrack? current = await _mediaCast.getCurrentSubtitleTrack(deviceUdn);
    
    // Set a specific subtitle track
    await _mediaCast.setSubtitleTrack(deviceUdn, 'sub1');
    
    // Disable subtitles
    await _mediaCast.setSubtitleTrack(deviceUdn, null);
  }
}
```

### Browse Media Server Content

```dart
Future<void> _browseMediaServer(DlnaDevice server) async {
  try {
    // Browse root directory
    List<MediaItem> rootItems = await _mediaCast.browseContentDirectory(
      server.udn,
      '0', // Root container ID
      0,   // Start index
      50,  // Count
    );
    
    // Filter by content type
    final videoItems = rootItems.where((item) => 
        item.mimeType?.startsWith('video/') ?? false).toList();
    
    final audioItems = rootItems.where((item) => 
        item.mimeType?.startsWith('audio/') ?? false).toList();
    
    print('Found ${videoItems.length} videos and ${audioItems.length} audio files');
    
    // Search for specific content
    List<MediaItem> searchResults = await _mediaCast.searchContentDirectory(
      server.udn,
      '0',
      'dc:title contains "movie"',
      0,
      20,
    );
    
  } catch (e) {
    print('Failed to browse content: $e');
  }
}
```

## 🔧 Error Handling & Troubleshooting

### Common Issues and Solutions

#### 1. UPnP Service Not Initialized
```dart
Future<bool> _ensureServiceReady() async {
  if (!await _mediaCast.isUpnpServiceInitialized()) {
    await _mediaCast.initializeUpnpService();
    
    // Wait a bit for service to be ready
    await Future.delayed(Duration(seconds: 2));
    
    return await _mediaCast.isUpnpServiceInitialized();
  }
  return true;
}
```

#### 2. No Devices Found
```dart
Future<void> _troubleshootDiscovery() async {
  // Check network permissions
  print('1. Ensure WIFI permissions are granted');
  print('2. Check if device is on same network as DLNA devices');
  print('3. Verify DLNA devices are powered on and discoverable');
  
  // Try refreshing a specific device
  try {
    final refreshedDevice = await _mediaCast.refreshDevice('known-device-udn');
    print('Device refreshed: ${refreshedDevice?.friendlyName}');
  } catch (e) {
    print('Failed to refresh device: $e');
  }
}
```

#### 3. Playback Issues
```dart
Future<void> _diagnosePlayback(String deviceUdn) async {
  try {
    // Check device services
    final services = await _mediaCast.getDeviceServices(deviceUdn);
    print('Available services: ${services.map((s) => s.serviceType).join(', ')}');
    
    // Verify AVTransport service
    bool hasAVTransport = await _mediaCast.hasService(deviceUdn, 'AVTransport');
    print('Has AVTransport: $hasAVTransport');
    
    // Check current state
    final state = await _mediaCast.getTransportState(deviceUdn);
    print('Current transport state: $state');
    
  } catch (e) {
    print('Diagnostic failed: $e');
  }
}
```

## 📋 Complete Example

Here's a complete working example that demonstrates all major features:

```dart
import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';

class DlnaMediaCastDemo extends StatefulWidget {
  @override
  _DlnaMediaCastDemoState createState() => _DlnaMediaCastDemoState();
}

class _DlnaMediaCastDemoState extends State<DlnaMediaCastDemo> {
  final _mediaCast = MediaCastDlna();
  List<DlnaDevice> _devices = [];
  DlnaDevice? _selectedRenderer;
  bool _isDiscovering = false;
  TransportState _currentState = TransportState.stopped;
  int _currentPosition = 0;
  int _duration = 0;
  
  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }
  
  Future<void> _initializePlugin() async {
    try {
      await _mediaCast.initializeUpnpService();
      print('✅ Media Cast DLNA initialized successfully');
    } catch (e) {
      print('❌ Initialization failed: $e');
    }
  }
  
  Future<void> _startDiscovery() async {
    setState(() => _isDiscovering = true);
    
    try {
      await _mediaCast.startDiscovery(DiscoveryOptions(timeoutSeconds: 15));
      
      // Poll for devices
      Timer.periodic(Duration(seconds: 2), (timer) async {
        final devices = await _mediaCast.getDiscoveredDevices();
        setState(() => _devices = devices);
        
        if (timer.tick >= 10) {
          timer.cancel();
          await _mediaCast.stopDiscovery();
          setState(() => _isDiscovering = false);
        }
      });
    } catch (e) {
      setState(() => _isDiscovering = false);
      _showError('Discovery failed: $e');
    }
  }
  
  Future<void> _castSampleVideo() async {
    if (_selectedRenderer == null) {
      _showError('Please select a renderer device first');
      return;
    }
    
    const sampleUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    
    try {
      final metadata = MediaMetadata(
        title: 'Big Buck Bunny',
        artist: 'Blender Foundation',
        duration: 596,
        mimeType: 'video/mp4',
      );
      
      await _mediaCast.setMediaUri(_selectedRenderer!.udn, sampleUrl, metadata);
      await _mediaCast.play(_selectedRenderer!.udn);
      
      _showSuccess('Video cast successfully!');
      _startStatusPolling();
      
    } catch (e) {
      _showError('Failed to cast video: $e');
    }
  }
  
  void _startStatusPolling() {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_selectedRenderer == null) {
        timer.cancel();
        return;
      }
      
      try {
        final state = await _mediaCast.getTransportState(_selectedRenderer!.udn);
        final position = await _mediaCast.getCurrentPosition(_selectedRenderer!.udn);
        final playbackInfo = await _mediaCast.getPlaybackInfo(_selectedRenderer!.udn);
        
        setState(() {
          _currentState = state;
          _currentPosition = position;
          _duration = playbackInfo.duration ?? 0;
        });
        
        // Stop polling if not playing
        if (state == TransportState.stopped) {
          timer.cancel();
        }
      } catch (e) {
        print('Status update failed: $e');
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Cast DLNA Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Discovery Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Device Discovery', 
                         style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isDiscovering ? null : _startDiscovery,
                      child: Text(_isDiscovering ? 'Discovering...' : 'Start Discovery'),
                    ),
                    SizedBox(height: 8),
                    Text('Found ${_devices.length} devices'),
                  ],
                ),
              ),
            ),
            
            // Device List
            Expanded(
              child: Card(
                child: _devices.isEmpty
                    ? Center(child: Text('No devices found'))
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          final isRenderer = device.deviceType.contains('MediaRenderer');
                          final isSelected = device.udn == _selectedRenderer?.udn;
                          
                          return ListTile(
                            leading: Icon(
                              isRenderer ? Icons.tv : Icons.folder,
                              color: isRenderer ? Colors.blue : Colors.orange,
                            ),
                            title: Text(device.friendlyName),
                            subtitle: Text('${device.manufacturerName} • ${device.ipAddress}'),
                            trailing: isRenderer
                                ? ElevatedButton(
                                    onPressed: () => setState(() => _selectedRenderer = device),
                                    child: Text(isSelected ? 'Selected' : 'Select'),
                                  )
                                : null,
                            selected: isSelected,
                          );
                        },
                      ),
              ),
            ),
            
            // Control Section
            if (_selectedRenderer != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Casting to: ${_selectedRenderer!.friendlyName}',
                           style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 16),
                      
                      // Cast button
                      ElevatedButton.icon(
                        onPressed: _castSampleVideo,
                        icon: Icon(Icons.cast),
                        label: Text('Cast Sample Video'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () => _mediaCast.previous(_selectedRenderer!.udn),
                            icon: Icon(Icons.skip_previous),
                          ),
                          IconButton(
                            onPressed: () => _mediaCast.play(_selectedRenderer!.udn),
                            icon: Icon(Icons.play_arrow, color: Colors.green),
                          ),
                          IconButton(
                            onPressed: () => _mediaCast.pause(_selectedRenderer!.udn),
                            icon: Icon(Icons.pause, color: Colors.orange),
                          ),
                          IconButton(
                            onPressed: () => _mediaCast.stop(_selectedRenderer!.udn),
                            icon: Icon(Icons.stop, color: Colors.red),
                          ),
                          IconButton(
                            onPressed: () => _mediaCast.next(_selectedRenderer!.udn),
                            icon: Icon(Icons.skip_next),
                          ),
                        ],
                      ),
                      
                      // Status
                      if (_currentState != TransportState.stopped) ...[
                        SizedBox(height: 8),
                        Text('Status: ${_currentState.toString().split('.').last}'),
                        Text('Position: ${_formatDuration(_currentPosition)} / ${_formatDuration(_duration)}'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
```

## 📚 API Reference

### Core Classes

#### `MediaCastDlna`
Main plugin class for DLNA operations.

**Methods:**
- `initializeUpnpService()` - Initialize the UPnP service
- `isUpnpServiceInitialized()` - Check if service is ready
- `startDiscovery(options)` - Start device discovery
- `stopDiscovery()` - Stop device discovery
- `getDiscoveredDevices()` - Get list of discovered devices

#### `DlnaDevice`
Represents a discovered DLNA/UPnP device.

**Properties:**
- `udn` - Unique Device Name
- `friendlyName` - Human-readable name
- `deviceType` - Type (MediaRenderer/MediaServer)
- `manufacturerName` - Device manufacturer
- `modelName` - Device model
- `ipAddress` - Device IP address

#### `MediaMetadata`
Metadata for media content.

**Properties:**
- `title` - Media title
- `artist` - Artist/creator name
- `duration` - Duration in seconds
- `mimeType` - MIME type (video/mp4, audio/mp3, etc.)

#### `TransportState`
Enum representing playback state.

**Values:**
- `playing` - Currently playing
- `paused` - Paused
- `stopped` - Stopped
- `transitioning` - Changing state

## 🛠️ Development & Contribution

### Built With Pigeon

This plugin uses [Pigeon](https://pub.dev/packages/pigeon) for generating type-safe platform interfaces. The API definitions are in `pigeons/media_cast_dlna.dart`.

To regenerate platform interfaces:
```bash
flutter packages pub run pigeon --input pigeons/media_cast_dlna.dart
```

### Project Structure
```
media_cast_dlna/
├── pigeons/                    # Pigeon interface definitions
├── lib/                       # Dart implementation
├── android/                   # Android implementation (Kotlin)
├── ios/                      # iOS implementation (Swift) - Coming Soon
└── example/                  # Example app
```

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📖 Learning Resources

- [DLNA/UPnP Specification](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v2.0.pdf)
- [Flutter Plugin Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [Pigeon Documentation](https://pub.dev/packages/pigeon)

## 🆘 Support & Issues

Having trouble? Here's how to get help:

1. **Check the [Example App](example/)** - See complete working implementation
2. **Search [Issues](https://github.com/felnanuke2/media_cast_dlna/issues)** - Your problem might already be solved
3. **Create an Issue** - Provide detailed information about your problem
4. **Join Discussions** - Connect with other developers using this plugin

### When Reporting Issues:
- Flutter version
- Plugin version
- Platform (Android version)
- Device model you're trying to cast to
- Complete error logs
- Minimal code example that reproduces the issue

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **jUPnP Team** - For the excellent Java UPnP library
- **Flutter Team** - For the amazing framework
- **Pigeon Contributors** - For the fantastic code generation tool
- **Community** - For feedback, testing, and contributions

---

<div align="center">

**Made with ❤️ for the Flutter community**

*Star ⭐ this repository if it helped you!*

</div>

<a href='https://ko-fi.com/Y8Y61HCG2P' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi5.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>


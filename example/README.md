# 📺 DLNA Media Cast Demo

A comprehensive Flutter example app that demonstrates how to use the [media_cast_dlna](https://pub.dev/packages/media_cast_dlna) plugin for discovering and controlling DLNA/UPnP devices on your local network.

## 🚀 Features

This example app showcases all the capabilities of the media_cast_dlna plugin:

- **🔍 Device Discovery**: Automatic discovery of DLNA/UPnP devices on your local network
- **📱 Device Selection**: Interactive modal to select and connect to media renderers
- **🎮 Playback Control**: Complete media control (play, pause, stop, seek, volume)
- **📊 Real-time Monitoring**: Live updates of playback state and device connectivity
- **🎵 Test Media**: Built-in collection of sample media for testing
- **🔗 Custom Media URL**: Support for playing custom media URLs
- **🎨 Modern UI**: Clean, responsive interface with material design
- **📱 Connectivity Handling**: Robust offline/online device state management

## 📁 Project Structure

The example follows a clean, modular architecture:

```
lib/
├── main.dart                           # Main application entry point
├── cast_devices_modal.dart            # Device selection modal
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Application constants
│   ├── models/
│   │   └── app_models.dart            # Data models
│   ├── theme/
│   │   └── app_theme.dart             # App theme configuration
│   └── utils/
│       ├── format_utils.dart          # Formatting utilities
│       ├── media_utils.dart           # Media handling utilities
│       └── ui_utils.dart              # UI helper functions
├── data/
│   └── repositories/
│       └── test_media_repository.dart # Sample media data
├── presentation/
│   └── widgets/
│       ├── device_selection_widget.dart    # Device selection UI
│       ├── playback_control_widget.dart    # Playback controls
│       └── test_media_widget.dart          # Test media section
└── services/
    └── media_cast_service.dart        # Media casting service layer
```

## 🛠️ Key Components

### MediaCastService
The core service that handles all DLNA operations:
- Device discovery and connection management
- Playback control and monitoring
- Volume and mute control
- Connectivity state tracking

### Playback Control Widget
Comprehensive playback controls including:
- Play/Pause/Stop buttons
- Seek bar with real-time position updates
- Volume control with mute toggle
- Track information display

### Device Selection Modal
Interactive device discovery and selection:
- Real-time device scanning
- Device details view
- Connection status indicators
- Device type filtering (Media Renderers)

### Test Media Repository
Sample media content for testing:
- Various media formats (MP4, MP3, etc.)
- Different resolutions and qualities
- Subtitle track examples
- Remote and local media URLs

## 🎯 How to Use

### 1. Launch the App
```bash
flutter run
```

### 2. Device Discovery
- Tap the cast icon in the app bar
- Wait for devices to appear in the modal
- Select a DLNA/UPnP media renderer from the list

### 3. Media Playback
- Choose from the test media collection
- Or enter a custom media URL
- Use the playback controls to manage playback
- Monitor real-time playback state

### 4. Advanced Features
- View device details by tapping the info icon
- Handle device offline/online states
- Control volume and mute settings
- Seek to specific positions in media

## 🔧 Technical Implementation

### State Management
- Uses Flutter's built-in `setState()` for simplicity
- Reactive UI updates based on service events
- Proper lifecycle management for timers and resources

### Error Handling
- Comprehensive error handling with user-friendly messages
- Graceful degradation when devices go offline
- Retry mechanisms for network operations

### Performance
- Efficient timer management for real-time updates
- Minimal rebuilds with targeted state updates
- Memory leak prevention with proper disposal

## 📱 Platform Support

- **Android**: Full support (API 21+)
- **iOS**: Coming soon

## 🧪 Testing

The example includes extensive test media for various scenarios:
- Different video formats and codecs
- Audio-only content
- Various resolutions (480p, 720p, 1080p)
- Subtitle tracks
- Different streaming protocols

## 🔍 Troubleshooting

### No Devices Found
- Ensure devices are on the same network
- Check firewall settings
- Verify DLNA/UPnP is enabled on target devices

### Playback Issues
- Test with different media URLs
- Check device compatibility
- Verify network connectivity

### Connection Problems
- Restart the app
- Check device power state
- Verify network stability

## 📚 Learning Resources

This example demonstrates:
- Clean architecture patterns
- Service layer implementation
- State management best practices
- Error handling strategies
- Timer and resource management
- Modern Flutter UI patterns

## 🤝 Contributing

Feel free to contribute improvements to this example:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This example is part of the media_cast_dlna plugin and is released under the MIT License.

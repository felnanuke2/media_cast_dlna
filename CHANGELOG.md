# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-07-01

### Added
- 🎉 **Initial release of Media Cast DLNA plugin**
- 🔍 **Device Discovery**: Automatic discovery of DLNA/UPnP devices on local network
- 📱 **Media Renderer Control**: Complete playback control (play, pause, stop, seek, volume)
- 📂 **Media Server Integration**: Browse and search content from DLNA media servers
- 🎬 **Advanced Subtitle Support**: Handle subtitle tracks for enhanced viewing experience
- ⚡ **Real-time Events**: Get instant updates on playback state, position, and volume changes
- 🔧 **Native Performance**: Built with Pigeon for type-safe platform interfaces
- 🤖 **Android Support**: Full implementation using jUPnP library (API 21+)
- 📖 **Comprehensive Documentation**: Complete API reference and examples
- 🎯 **Example App**: Working demonstration of all plugin features

### Platform Support
- ✅ Android (API 21+)
- 🚧 iOS (Coming in next release)

### Features
- Device discovery with automatic network scanning
- Media renderer selection and control
- Playback management (play, pause, stop, seek, next, previous)
- Volume control and mute functionality
- Subtitle track management
- Media server content browsing
- Real-time status monitoring
- Error handling and diagnostics
- Type-safe native interfaces via Pigeon

### Dependencies
- Flutter 3.3.0+
- Dart 3.8.1+
- plugin_platform_interface ^2.0.2
- pigeon ^22.7.0 (dev dependency)

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3] - 2025-07-05

### ✨ New Features
- **Playback Speed Control**: Added `setPlaybackSpeed()` method for controlling media playback rate
  - New `PlaybackSpeed` class with configurable speed values (e.g., 0.5x, 1.0x, 1.25x, 2.0x)
  - Support for variable speed playback on compatible DLNA devices
  - ⚠️ **Device Support Warning**: Not all DLNA media renderers support playback speed control

### 🔧 Technical Improvements
- **Pigeon Code Generation**: Regenerated platform interfaces with latest Pigeon version
- **Type Safety**: Enhanced type safety for new playback speed functionality
- **Platform Interface**: Updated native Android implementation for speed control

### ⚠️ Important Notes
- **Subtitle Support**: Subtitle control methods may not work on all DLNA devices
- **Playback Speed**: Speed control functionality is device-dependent
- **Device Compatibility**: We recommend testing these features with your specific devices

### 📖 Documentation Updates
- Added warnings about device compatibility for subtitle and playback speed features
- Updated API documentation with new playback speed methods
- Enhanced troubleshooting guide for feature compatibility

## [0.1.2] - 2025-07-05

### 🍎 iOS Support Temporarily Removed
- **Platform Focus**: Temporarily removed iOS support to focus on Android platform
- **Apple Privacy Limitations**: iOS discovery requires multicast permissions that are difficult to obtain due to Apple's privacy restrictions
- **Future Consideration**: iOS support may be added in future releases, potentially using AirPlay for iOS devices
- **Android Only**: Plugin now exclusively supports Android platform (API 21+)

### 🔧 Technical Changes
- Removed iOS folder and all iOS-specific code
- Updated pubspec.yaml to remove iOS platform support
- Updated documentation to reflect Android-only support
- Simplified build configuration for Android-only development

### 📖 Documentation Updates
- Updated README to explain Android-only support
- Added explanation about Apple's privacy limitations
- Suggested AirPlay as alternative for iOS casting
- Updated installation instructions for Android-only setup

## [0.1.1] - 2025-07-03

### 🔄 Refactored
- **Example App Complete Restructure**: Major refactoring of the example application with clean architecture
- **Service Layer Implementation**: Added dedicated `MediaCastService` for better separation of concerns
- **Modular Widget Architecture**: Split UI into focused, reusable widgets
- **State Management Improvements**: Enhanced state management with proper lifecycle handling

### ✨ Enhanced
- **Device Details Modal**: Improved device selection with detailed information display
- **Real-time Monitoring**: Enhanced connectivity and playback state monitoring
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **UI/UX Improvements**: Modern, responsive interface with better visual feedback
- **Code Organization**: Clean folder structure with proper separation of concerns

### 🏗️ Architecture
- **Clean Architecture**: Implemented layered architecture (presentation, services, data, core)
- **Repository Pattern**: Added test media repository for better data management
- **Utility Classes**: Centralized utility functions for formatting, media handling, and UI operations
- **Constants Management**: Centralized configuration and constants
- **Theme System**: Dedicated theme configuration for consistent styling

### 📁 New Structure
- `core/` - Constants, models, themes, and utilities
- `data/` - Repositories and data sources
- `presentation/` - Widgets and UI components
- `services/` - Business logic and external API interactions

### 🔧 Technical Improvements
- **Timer Management**: Improved timer handling for real-time updates
- **Memory Management**: Better resource cleanup and disposal
- **Performance**: Optimized rendering and state updates
- **Type Safety**: Enhanced type safety throughout the codebase

### 📖 Documentation
- **Comprehensive Example README**: Detailed documentation for the example app
- **Code Comments**: Improved inline documentation
- **Architecture Guide**: Clear explanation of the project structure

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
- ❌ iOS (Temporarily removed due to Apple privacy limitations)

### Features
- Device discovery with automatic network scanning
- Media renderer selection and control
- Playback management (play, pause, stop, seek)
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

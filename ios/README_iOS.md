# iOS Implementation Guide

## Overview

This document describes the iOS implementation of the MediaCast DLNA Flutter plugin. The iOS implementation provides comprehensive DLNA/UPnP functionality comparable to the Android version.

## Architecture

### Core Components

1. **MediaCastDlnaPlugin.swift** - Main plugin class implementing the Pigeon API interface
2. **UPnAtomImplementation.swift** - UPnAtom-based device discovery and media control
3. **UPnPDeviceDiscovery.swift** - Fallback SSDP discovery using iOS Network framework  
4. **DeviceDiscoveryManager.swift** - Device and service management
5. **MediaControlManager.swift** - Media playback control with session management
6. **VolumeManager.swift** - Volume and mute control functionality
7. **DidlMetadataConverter.swift** - Metadata to DIDL-Lite XML conversion
8. **SOAPClient.swift** - Fallback HTTP client for UPnP SOAP communication

## Key Features

### Device Discovery
- SSDP multicast discovery using iOS Network framework
- Automatic device description parsing
- Service enumeration and capability detection
- Real-time device list updates

### Media Control
- SetAVTransportURI with metadata support
- Transport controls (play, pause, stop, seek, next, previous)
- Position and state tracking
- Subtitle track management

### Volume Control
- Volume level setting (0-100)
- Mute/unmute functionality
- Volume state querying

### Metadata Handling
- Support for Audio, Video, and Image metadata
- DIDL-Lite XML generation
- Subtitle track integration
- UPnP class mapping

## iOS-Specific Implementation Details

### Network Framework Usage
The implementation uses iOS's modern Network framework for UDP socket communication, providing:
- Better IPv6 support
- Improved battery efficiency
- Proper background handling
- Network path monitoring

### Async/Await Support
All network operations use Swift's async/await for:
- Clean asynchronous code
- Proper error handling
- Cancellation support
- Better performance

### Logging
Comprehensive logging using OSLog for:
- Discovery events
- SOAP communications
- Error tracking
- Performance monitoring

## Platform Requirements

- iOS 12.0+
- Swift 5.0+
- Network framework support

## Dependencies

The iOS implementation uses:
- **System frameworks**: Foundation, Network, UIKit, SystemConfiguration, Darwin
- **UPnAtom**: Modern Swift UPnP library optimized for iOS (~1.0)

## Key Advantages of UPnAtom Integration

### Modern Swift Architecture
- **Pure Swift implementation** with modern language features
- **Clean API design** following Swift conventions
- **Lightweight footprint** with minimal dependencies
- **iOS-optimized networking** for better performance

### Enhanced Development Experience
- **Type-safe UPnP operations** with Swift's type system
- **Async/await support** for modern concurrency patterns
- **Notification-based discovery** for real-time updates
- **Easy debugging** with clear Swift stack traces

## Usage

The iOS implementation automatically registers with Flutter when the plugin is initialized. All functionality is exposed through the same Dart API as the Android version.

## Limitations and Future Improvements

### Current Limitations
1. Some SOAP operations are simulated rather than fully implemented
2. Content Directory browsing needs full DIDL-Lite parsing
3. Event subscription for real-time updates not implemented
4. Advanced UPnP features (authentication, etc.) not supported

### Future Enhancements
1. Full SOAP client with proper XML parsing
2. UPnP event subscription support
3. Background discovery capabilities
4. Advanced device capabilities detection
5. Better error handling and recovery

## Testing

The implementation includes comprehensive logging for debugging and testing. Use Console.app or Xcode's debug console to monitor plugin activity.

## Troubleshooting

### Common Issues
1. **Discovery not working**: Check network permissions and ensure devices are on same network
2. **SOAP calls failing**: Verify device supports required UPnP services
3. **Playback issues**: Check media format compatibility with target device

### Debug Logging
Enable debug logging by setting appropriate log levels in OSLog configuration.

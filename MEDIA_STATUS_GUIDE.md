# Media Status Monitoring

This document explains how to monitor media playback status using the Media Cast DLNA plugin.

## Overview

The plugin provides real-time monitoring of media playback status through UPnP eventing and polling. You can receive notifications about:

- Transport state changes (playing, paused, stopped)
- Playback position updates
- Volume changes
- Track changes
- Playback errors

## Quick Start

### 1. Listen to Events

```dart
import 'package:media_cast_dlna/media_cast_dlna.dart';

final controller = MediaCastDlnaController.instance;

// Listen to transport state changes
controller.onTransportStateChanged.listen((event) {
  print('Device ${event.deviceUdn} state: ${event.state}');
});

// Listen to position changes (updated every second during playback)
controller.onPositionChanged.listen((event) {
  print('Position: ${event.positionSeconds} seconds');
});

// Listen to volume changes
controller.onVolumeChanged.listen((event) {
  print('Volume: ${event.volumeInfo.volume}%, Muted: ${event.volumeInfo.muted}');
});

// Listen to track changes
controller.onTrackChanged.listen((event) {
  print('New track: ${event.trackUri}');
});

// Listen to playback errors
controller.onPlaybackError.listen((event) {
  print('Playback error on ${event.deviceUdn}: ${event.error}');
});
```

### 2. Start Media with Automatic Monitoring

When you start playing media, monitoring is automatically enabled:

```dart
// This will automatically start monitoring after successful playback
await controller.setMediaUri(device.udn, 'http://example.com/video.mp4', '');
await controller.play(device.udn);
```

### 3. Manual Event Subscription

You can manually subscribe to specific service events:

```dart
// Subscribe to AVTransport service events
await controller.subscribeToEvents(device.udn, 'AVTransport');

// Subscribe to RenderingControl service events  
await controller.subscribeToEvents(device.udn, 'RenderingControl');

// Unsubscribe when done
await controller.unsubscribeFromEvents(device.udn, 'AVTransport');
```

### 4. Query Current State

Get the current transport state synchronously:

```dart
final currentState = await controller.getTransportState(device.udn);
print('Current state: $currentState');
```

## Event Types

### Transport State Changes

Triggered when playback state changes:

```dart
controller.onTransportStateChanged.listen((event) {
  switch (event.state) {
    case TransportState.playing:
      // Media is playing
      break;
    case TransportState.paused:
      // Media is paused
      break;
    case TransportState.stopped:
      // Media is stopped
      break;
    case TransportState.transitioning:
      // State is transitioning
      break;
    case TransportState.noMediaPresent:
      // No media loaded
      break;
  }
});
```

### Position Updates

Provides real-time playback position (updated every second):

```dart
controller.onPositionChanged.listen((event) {
  final minutes = event.positionSeconds ~/ 60;
  final seconds = event.positionSeconds % 60;
  print('Position: $minutes:${seconds.toString().padLeft(2, '0')}');
});
```

### Volume Changes

Notifies when volume or mute state changes:

```dart
controller.onVolumeChanged.listen((event) {
  final volume = event.volumeInfo.volume; // 0-100
  final muted = event.volumeInfo.muted;   // true/false
  
  if (muted) {
    print('Audio is muted');
  } else {
    print('Volume: $volume%');
  }
});
```

### Track Changes

Triggered when a new track starts playing:

```dart
controller.onTrackChanged.listen((event) {
  print('Track URI: ${event.trackUri}');
  print('Metadata: ${event.trackMetadata}');
});
```

### Playback Errors

Notifies about playback-related errors:

```dart
controller.onPlaybackError.listen((event) {
  print('Error on device ${event.deviceUdn}: ${event.error}');
  // Handle error (show user notification, retry, etc.)
});
```

## Implementation Details

### Automatic Monitoring

- Monitoring starts automatically when you call `play()` or `castVideo()`
- Monitoring stops automatically when you call `stop()`
- Position polling occurs every 1 second during playback

### UPnP Event Subscriptions

The plugin uses UPnP GENA (Generic Event Notification Architecture) to receive real-time notifications from DLNA devices:

- **AVTransport Service**: Transport state, track changes
- **RenderingControl Service**: Volume, mute state changes

### Fallback Polling

For devices that don't support eventing or for position updates, the plugin uses polling:

- Position is polled every second during playback
- Polling automatically stops when media is stopped

### Error Handling

- Network errors are reported through `onPlaybackError`
- Subscription failures are logged but don't interrupt playback
- Polling continues even if event subscriptions fail

## Best Practices

### 1. Resource Management

Always clean up subscriptions when done:

```dart
class MyMediaPlayer extends StatefulWidget {
  // ...
}

class _MyMediaPlayerState extends State<MyMediaPlayer> {
  late StreamSubscription _stateSubscription;
  late StreamSubscription _positionSubscription;
  
  @override
  void initState() {
    super.initState();
    _stateSubscription = controller.onTransportStateChanged.listen(/* ... */);
    _positionSubscription = controller.onPositionChanged.listen(/* ... */);
  }
  
  @override
  void dispose() {
    _stateSubscription.cancel();
    _positionSubscription.cancel();
    super.dispose();
  }
}
```

### 2. Filter by Device

Always filter events by device UDN when handling multiple devices:

```dart
controller.onTransportStateChanged.listen((event) {
  if (event.deviceUdn == currentDevice.udn) {
    // Handle event for current device only
    updateUI(event.state);
  }
});
```

### 3. Handle Errors Gracefully

```dart
controller.onPlaybackError.listen((event) {
  // Log the error
  print('Playback error: ${event.error}');
  
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Playback error occurred')),
  );
  
  // Optionally retry or fallback
});
```

### 4. UI Updates

Use the events to update your UI in real-time:

```dart
class MediaControls extends StatefulWidget {
  // ...
}

class _MediaControlsState extends State<MediaControls> {
  TransportState _state = TransportState.stopped;
  int _position = 0;
  
  @override
  void initState() {
    super.initState();
    
    controller.onTransportStateChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _state = event.state;
        });
      }
    });
    
    controller.onPositionChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _position = event.positionSeconds;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Play/Pause button with current state
        IconButton(
          icon: Icon(_state == TransportState.playing 
            ? Icons.pause 
            : Icons.play_arrow),
          onPressed: () {
            if (_state == TransportState.playing) {
              controller.pause(widget.device.udn);
            } else {
              controller.play(widget.device.udn);
            }
          },
        ),
        
        // Position display
        Text('${_position ~/ 60}:${(_position % 60).toString().padLeft(2, '0')}'),
        
        // Progress bar
        LinearProgressIndicator(
          value: _position / _totalDuration,
        ),
      ],
    );
  }
}
```

## Example App

See `/example/lib/media_status_example.dart` for a complete example showing all media status features in action.

## Troubleshooting

### Events Not Received

1. Check if device supports UPnP eventing
2. Verify network connectivity
3. Check device logs for subscription errors

### Position Updates Inconsistent

1. Some devices don't support GetPositionInfo
2. Position polling may fail on certain media types
3. Network latency can affect update frequency

### High Battery Usage

1. Unsubscribe from events when not needed
2. Consider reducing polling frequency for background apps
3. Stop monitoring when app goes to background

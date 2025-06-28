import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'dart:async';

class MediaStatusExample extends StatefulWidget {
  final DlnaDevice device;

  const MediaStatusExample({Key? key, required this.device}) : super(key: key);

  @override
  State<MediaStatusExample> createState() => _MediaStatusExampleState();
}

class _MediaStatusExampleState extends State<MediaStatusExample> {
  final _controller = MediaCastDlnaController.instance;
  late StreamSubscription<({String deviceUdn, TransportState state})> _stateSubscription;
  late StreamSubscription<({String deviceUdn, int positionSeconds})> _positionSubscription;
  late StreamSubscription<({String deviceUdn, VolumeInfo volumeInfo})> _volumeSubscription;
  late StreamSubscription<({String deviceUdn, String? trackUri, String? trackMetadata})> _trackSubscription;
  late StreamSubscription<({String deviceUdn, String error})> _errorSubscription;

  TransportState _currentState = TransportState.stopped;
  int _currentPosition = 0;
  VolumeInfo _currentVolume = VolumeInfo(volume: 50, muted: false);
  String? _currentTrackUri;
  String? _currentTrackMetadata;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _positionSubscription.cancel();
    _volumeSubscription.cancel();
    _trackSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
  }

  void _setupEventListeners() {
    // Listen to transport state changes
    _stateSubscription = _controller.onTransportStateChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _currentState = event.state;
        });
        _showSnackBar('Transport state changed to: ${event.state.name}');
      }
    });

    // Listen to position changes
    _positionSubscription = _controller.onPositionChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _currentPosition = event.positionSeconds;
        });
      }
    });

    // Listen to volume changes
    _volumeSubscription = _controller.onVolumeChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _currentVolume = event.volumeInfo;
        });
        _showSnackBar('Volume changed to: ${event.volumeInfo.volume}%');
      }
    });

    // Listen to track changes
    _trackSubscription = _controller.onTrackChanged.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _currentTrackUri = event.trackUri;
          _currentTrackMetadata = event.trackMetadata;
        });
        _showSnackBar('Track changed: ${event.trackUri}');
      }
    });

    // Listen to playback errors
    _errorSubscription = _controller.onPlaybackError.listen((event) {
      if (event.deviceUdn == widget.device.udn) {
        setState(() {
          _lastError = event.error;
        });
        _showSnackBar('Playback error: ${event.error}', isError: true);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Color _getStateColor(TransportState state) {
    switch (state) {
      case TransportState.playing:
        return Colors.green;
      case TransportState.paused:
        return Colors.orange;
      case TransportState.stopped:
        return Colors.red;
      case TransportState.transitioning:
        return Colors.blue;
      case TransportState.noMediaPresent:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media Status - ${widget.device.friendlyName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device: ${widget.device.friendlyName}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('UDN: ${widget.device.udn}'),
                    Text('IP: ${widget.device.ipAddress}:${widget.device.port}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Transport State
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _currentState == TransportState.playing
                          ? Icons.play_arrow
                          : _currentState == TransportState.paused
                              ? Icons.pause
                              : Icons.stop,
                      color: _getStateColor(_currentState),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transport State',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _currentState.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStateColor(_currentState),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Position
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playback Position',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_currentPosition),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Volume
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Volume',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _currentVolume.muted
                              ? Icons.volume_off
                              : _currentVolume.volume > 50
                                  ? Icons.volume_up
                                  : Icons.volume_down,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _currentVolume.volume / 100.0,
                            backgroundColor: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${_currentVolume.volume}%'),
                      ],
                    ),
                    if (_currentVolume.muted)
                      const Text(
                        'MUTED',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Track
            if (_currentTrackUri != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Track',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'URI: $_currentTrackUri',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      if (_currentTrackMetadata != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Metadata: $_currentTrackMetadata',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error Display
            if (_lastError != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Last Error',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Control Buttons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _controller.subscribeToEvents(
                              widget.device.udn,
                              'AVTransport',
                            );
                            _showSnackBar('Subscribed to AVTransport events');
                          } catch (e) {
                            _showSnackBar('Failed to subscribe: $e', isError: true);
                          }
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Subscribe'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _controller.unsubscribeFromEvents(
                              widget.device.udn,
                              'AVTransport',
                            );
                            _showSnackBar('Unsubscribed from events');
                          } catch (e) {
                            _showSnackBar('Failed to unsubscribe: $e', isError: true);
                          }
                        },
                        icon: const Icon(Icons.notifications_off),
                        label: const Text('Unsubscribe'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final state = await _controller.getTransportState(widget.device.udn);
                            setState(() {
                              _currentState = state;
                            });
                            _showSnackBar('Current state: ${state.name}');
                          } catch (e) {
                            _showSnackBar('Failed to get state: $e', isError: true);
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh State'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

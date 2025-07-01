import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DLNA Media Cast Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DlnaHomePage(),
    );
  }
}

class DlnaHomePage extends StatefulWidget {
  const DlnaHomePage({super.key});

  @override
  State<DlnaHomePage> createState() => _DlnaHomePageState();
}

class _DlnaHomePageState extends State<DlnaHomePage> {
  String _platformVersion = 'Unknown';
  late final MediaCastDlnaApi _api;
  final TextEditingController _customUrlController = TextEditingController();
  List<DlnaDevice> _discoveredDevices = [];
  DlnaDevice? _selectedDevice;
  String? _selectedRendererUdn;
  bool _isDiscovering = false;
  Timer? _discoveryTimer;
  Timer? _playbackInfoTimer;

  // Playback state
  int _currentPosition = 0;
  int _duration = 0;
  int _currentVolume = 50;
  bool _isMuted = false;
  TransportState _transportState = TransportState.stopped;
  String _currentTrackTitle = '';
  String? _currentThumbnailUrl;
  bool _isSliderBeingDragged = false;

  @override
  void initState() {
    super.initState();
    _api = MediaCastDlnaApi();
    initPlatformState();
    _initializeUpnpService();
  }

  Future<void> _initializeUpnpService() async {
    try {
      await _api.initializeUpnpService();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize UPnP service: $e')),
        );
      }
    }
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _api.getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _startDiscovery() async {
    try {
      setState(() {
        _isDiscovering = true;
      });

      // Start discovery
      final options = DiscoveryOptions(timeout: 10);
      await _api.startDiscovery(options);

      // Set up periodic polling for discovered devices
      _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (
        timer,
      ) async {
        if (_isDiscovering && mounted) {
          await _updateDiscoveredDevices();
        } else {
          timer.cancel();
        }
      });

      // Initial device fetch
      await _updateDiscoveredDevices();
    } catch (e) {
      setState(() {
        _isDiscovering = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Discovery failed: $e')));
    }
  }

  Future<void> _updateDiscoveredDevices() async {
    try {
      final devices = await _api.getDiscoveredDevices();
      setState(() {
        // Update discovered devices
        _discoveredDevices = devices;

        // Check if selected device is still available
        if (_selectedRendererUdn != null) {
          final selectedStillExists = devices.any(
            (d) => d.udn == _selectedRendererUdn,
          );
          if (!selectedStillExists) {
            _selectedDevice = null;
            _selectedRendererUdn = null;
          }
        }
      });
    } catch (e) {
      // Ignore errors during polling
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      _discoveryTimer?.cancel();
      await _api.stopDiscovery();
      setState(() {
        _isDiscovering = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stop discovery failed: $e')));
    }
  }

  void _selectRenderer(String rendererUdn) {
    setState(() {
      _selectedRendererUdn = rendererUdn;
      _selectedDevice = _discoveredDevices.firstWhere(
        (device) => device.udn == rendererUdn,
      );
    });

    // Start monitoring playback info for selected renderer
    _startPlaybackInfoMonitoring();
  }

  void _startPlaybackInfoMonitoring() {
    _playbackInfoTimer?.cancel();
    if (_selectedRendererUdn != null) {
      _playbackInfoTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) async {
        if (_selectedRendererUdn != null && mounted) {
          await _updatePlaybackInfo();
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _updatePlaybackInfo() async {
    if (_selectedRendererUdn == null) return;

    try {
      // Get transport state
      final transportState = await _api.getTransportState(
        _selectedRendererUdn!,
      );

      // Get current position if playing
      int currentPosition = 0;
      if (transportState == TransportState.playing ||
          transportState == TransportState.paused) {
        currentPosition = await _api.getCurrentPosition(_selectedRendererUdn!);
      }

      // Get playback info (includes duration and track info)
      PlaybackInfo? playbackInfo;
      try {
        playbackInfo = await _api.getPlaybackInfo(_selectedRendererUdn!);
      } catch (e) {
        // Ignore errors when getting playback info
      }

      // Get volume info
      VolumeInfo? volumeInfo;
      try {
        volumeInfo = await _api.getVolumeInfo(_selectedRendererUdn!);
      } catch (e) {
        // Ignore errors when getting volume info
      }

      if (mounted) {
        setState(() {
          _transportState = transportState;
          _currentPosition = currentPosition;
          if (playbackInfo != null) {
            _duration = playbackInfo.duration;
            // Parse track title from metadata if available
            _currentTrackTitle = _parseTrackTitleFromMetadata(
              playbackInfo.currentTrackMetadata,
            );
            // Parse thumbnail URL from metadata if available
            _currentThumbnailUrl = _getThumbnailUrlFromMetadata(
              playbackInfo.currentTrackMetadata,
            );
          }
          if (volumeInfo != null) {
            _currentVolume = volumeInfo.volume;
            _isMuted = volumeInfo.muted;
          }
        });
      }
    } catch (e) {
      // Ignore errors during monitoring
    }
  }

  String _parseTrackTitleFromMetadata(MediaMetadata? metadata) {
    if (metadata == null) return '';
    
    // Extract title based on metadata type
    switch (metadata) {
      case AudioMetadata audioMetadata:
        return audioMetadata.title ?? audioMetadata.album ?? 'Unknown Audio';
      case VideoMetadata videoMetadata:
        return videoMetadata.title ?? 'Unknown Video';
      case ImageMetadata imageMetadata:
        return imageMetadata.title ?? 'Unknown Image';
    }
  }

  String? _getThumbnailUrlFromMetadata(MediaMetadata? metadata) {
    if (metadata == null) return null;
    
    // Extract thumbnail/album art URL based on metadata type
    switch (metadata) {
      case AudioMetadata audioMetadata:
        return audioMetadata.albumArtUri;
      case VideoMetadata videoMetadata:
        return videoMetadata.thumbnailUri;
      case ImageMetadata imageMetadata:
        return imageMetadata.thumbnailUri;
    }
  }

  void _showDeviceDetails(DlnaDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Device Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', device.friendlyName),
                _buildDetailRow('UDN', device.udn),
                _buildDetailRow('Type', device.deviceType),
                _buildDetailRow('Manufacturer', device.manufacturerName),
                _buildDetailRow('Model', device.modelName),
                _buildDetailRow('IP Address', device.ipAddress),
                _buildDetailRow('Port', device.port.toString()),
                _buildDetailRow(
                  'Description',
                  device.modelDescription ?? 'No description',
                ),
                if (device.presentationUrl != null)
                  _buildDetailRow('Presentation URL', device.presentationUrl!),
                if (device.iconUrl != null)
                  _buildDetailRow('Icon URL', device.iconUrl!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // Test media options
  final List<Map<String, dynamic>> _testMediaOptions = [
    {
      'title': 'Big Buck Bunny (Video)',
      'url':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'type': 'video/mp4',
      'description': 'Open source 3D computer-animated comedy short film',
      'thumbnailUri':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      'duration': 596, // 9:56
    },
    {
      'title': 'Sintel Trailer (Video)',
      'url':
          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      'type': 'video/mp4',
      'description': 'Blender Foundation\'s third open movie',
      'thumbnailUri':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
      'duration': 888, // 14:48
    },
    {
      'title': 'Kalimba (Audio)',
      'url':
          'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3',
      'type': 'audio/mpeg',
      'description': 'Sample audio file for testing',
      'artist': 'Mr. Scruff',
      'album': 'Sample Music',
      'albumArtUri': 'https://picsum.photos/1920/1080',
      'genre': 'Electronic',
      'duration': 330, // 5:30
    },
    {
      'title': 'Sample Image',
      'url': 'https://picsum.photos/1920/1080',
      'type': 'image/jpeg',
      'description': 'Sample image for testing image display',
      'resolution': '1920x1080',
    },
  ];

  Future<void> _playSelectedMedia(Map<String, dynamic> media) async {
    if (_selectedRendererUdn == null) return;

    final mediaUrl = media['url'] as String;
    final mediaType = media['type'] as String;
    final title = media['title'] as String;
    final description = media['description'] as String;

    // Create appropriate MediaMetadata based on media type
    MediaMetadata metadata;
    if (mediaType.startsWith('video/')) {
      metadata = VideoMetadata(
        title: title,
        description: description,
        upnpClass: 'object.item.videoItem.movie',
        thumbnailUri: media['thumbnailUri'] as String?,
        duration: media['duration'] as int?,
        genre: media['genre'] as String?,
        resolution: media['resolution'] as String?,
        bitrate: media['bitrate'] as int?,
      );
    } else if (mediaType.startsWith('audio/')) {
      metadata = AudioMetadata(
        title: title,
        artist: media['artist'] as String? ?? 'Unknown Artist',
        album: media['album'] as String? ?? 'Unknown Album',
        description: description,
        upnpClass: 'object.item.audioItem.musicTrack',
        albumArtUri: media['albumArtUri'] as String?,
        genre: media['genre'] as String?,
        duration: media['duration'] as int?,
        originalTrackNumber: media['trackNumber'] as int?,
      );
    } else if (mediaType.startsWith('image/')) {
      metadata = ImageMetadata(
        title: title,
        description: description,
        upnpClass: 'object.item.imageItem.photo',
        resolution: media['resolution'] as String?,
        thumbnailUri: media['thumbnailUri'] as String?,
        date: media['date'] as String?,
      );
    } else {
      // Fallback for unknown media types
      metadata = AudioMetadata(
        title: title,
        artist: 'Unknown',
        album: 'Unknown',
        description: description,
        upnpClass: 'object.item',
      );
    }

    try {
      // Set media URI first, then play
      await _api.setMediaUri(_selectedRendererUdn!, mediaUrl, metadata);
      await _api.play(_selectedRendererUdn!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Playing: $title')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Play failed: $e')));
    }
  }

  Future<void> _playCustomUrl() async {
    if (_selectedRendererUdn == null ||
        _customUrlController.text.trim().isEmpty) {
      return;
    }

    final url = _customUrlController.text.trim();
    final metadata = AudioMetadata(
      title: 'Custom Media',
      artist: 'Unknown',
      album: 'Unknown',
      description: 'Custom Media',
      upnpClass: 'object.item',
    );

    try {
      // Set media URI first, then play
      await _api.setMediaUri(_selectedRendererUdn!, url, metadata);
      await _api.play(_selectedRendererUdn!);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playing custom media')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Play failed: $e')));
    }
  }

  Future<void> _controlPlayback(String action) async {
    if (_selectedRendererUdn == null) return;

    final actions = {
      'play': () => _api.play(_selectedRendererUdn!),
      'pause': () => _api.pause(_selectedRendererUdn!),
      'stop': () => _api.stop(_selectedRendererUdn!),
      'next': () => _api.next(_selectedRendererUdn!),
      'previous': () => _api.previous(_selectedRendererUdn!),
    };

    try {
      await actions[action]?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$action failed: $e')));
    }
  }

  Future<void> _setVolume(int volume) async {
    if (_selectedRendererUdn == null) return;

    try {
      await _api.setVolume(_selectedRendererUdn!, volume);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Set volume failed: $e')));
    }
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _playbackInfoTimer?.cancel();
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _seekTo(int positionSeconds) async {
    if (_selectedRendererUdn == null) return;

    try {
      await _api.seek(_selectedRendererUdn!, positionSeconds);
      setState(() {
        _currentPosition = positionSeconds;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Seek failed: $e')));
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getMediaIcon(String mediaType) {
    if (mediaType.startsWith('video/')) {
      return Icons.videocam;
    } else if (mediaType.startsWith('audio/')) {
      return Icons.music_note;
    } else if (mediaType.startsWith('image/')) {
      return Icons.image;
    } else {
      return Icons.file_present;
    }
  }

  Color _getMediaColor(String mediaType) {
    if (mediaType.startsWith('video/')) {
      return Colors.red;
    } else if (mediaType.startsWith('audio/')) {
      return Colors.blue;
    } else if (mediaType.startsWith('image/')) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  IconData _getTransportStateIcon() {
    switch (_transportState) {
      case TransportState.playing:
        return Icons.play_arrow;
      case TransportState.paused:
        return Icons.pause;
      case TransportState.stopped:
        return Icons.stop;
      case TransportState.transitioning:
        return Icons.sync;
      case TransportState.noMediaPresent:
        return Icons.music_off;
    }
  }

  Color _getTransportStateColor() {
    switch (_transportState) {
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

  String _getTransportStateText() {
    switch (_transportState) {
      case TransportState.playing:
        return 'Playing';
      case TransportState.paused:
        return 'Paused';
      case TransportState.stopped:
        return 'Stopped';
      case TransportState.transitioning:
        return 'Loading...';
      case TransportState.noMediaPresent:
        return 'No Media';
    }
  }

  Future<void> _toggleMute() async {
    if (_selectedRendererUdn == null) return;

    try {
      await _api.setMute(_selectedRendererUdn!, !_isMuted);
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Toggle mute failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DLNA Media Cast Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform: $_platformVersion'),
                  const SizedBox(height: 8),
                  Text('Discovered devices: ${_discoveredDevices.length}'),
                  if (_selectedDevice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected renderer: ${_selectedDevice?.friendlyName ?? "Unknown"}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isDiscovering ? null : _startDiscovery,
                    child: Text(
                      _isDiscovering ? 'Discovering...' : 'Start Discovery',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isDiscovering ? _stopDiscovery : null,
                    child: const Text('Stop Discovery'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _discoveredDevices.isEmpty
                  ? const Center(
                      child: Text(
                        'No devices discovered\nTap "Start Discovery" to find DLNA devices',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _discoveredDevices[index];
                        final isRenderer = device.deviceType.contains(
                          'MediaRenderer',
                        );
                        final isSelected = device.udn == _selectedRendererUdn;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              isRenderer ? Icons.tv : Icons.folder,
                              color: isRenderer ? Colors.blue : Colors.orange,
                            ),
                            title: Text(device.friendlyName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${device.manufacturerName} - ${device.modelName}',
                                ),
                                Text('Type: ${device.deviceType}'),
                                Text('IP: ${device.ipAddress}:${device.port}'),
                              ],
                            ),
                            trailing: isRenderer
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: isSelected
                                            ? null
                                            : () => _selectRenderer(device.udn),
                                        child: Text(
                                          isSelected ? 'Selected' : 'Select',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () =>
                                            _showDeviceDetails(device),
                                        icon: const Icon(Icons.info),
                                        tooltip: 'Device Details',
                                      ),
                                    ],
                                  )
                                : null,
                            selected: isSelected,
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_selectedRendererUdn != null)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const Divider(),
                  // Playback controls
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Playback Controls',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Thumbnail/Album Art and Track info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail/Album Art
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                ),
                                child: _currentThumbnailUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _currentThumbnailUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.grey[300],
                                              ),
                                              child: const Icon(
                                                Icons.music_note,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.grey[300],
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.music_note,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              // Track info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_currentTrackTitle.isNotEmpty) ...[
                                      Text(
                                        _currentTrackTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    // Transport state indicator
                                    Row(
                                      children: [
                                        Icon(
                                          _getTransportStateIcon(),
                                          color: _getTransportStateColor(),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getTransportStateText(),
                                          style: TextStyle(
                                            color: _getTransportStateColor(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Seek slider
                          Column(
                            children: [
                              Slider(
                                value: _isSliderBeingDragged
                                    ? _currentPosition.toDouble()
                                    : (_duration > 0
                                          ? _currentPosition.toDouble()
                                          : 0),
                                min: 0,
                                max: _duration > 0 ? _duration.toDouble() : 100,
                                onChanged: (value) {
                                  setState(() {
                                    _isSliderBeingDragged = true;
                                    _currentPosition = value.round();
                                  });
                                },
                                onChangeEnd: (value) {
                                  _seekTo(value.round());
                                  setState(() {
                                    _isSliderBeingDragged = false;
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(_currentPosition)),
                                  Text(_formatDuration(_duration)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, size: 32),
                                onPressed: () => _controlPlayback('previous'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  size: 36,
                                  color: Colors.green,
                                ),
                                onPressed: () => _controlPlayback('play'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.pause,
                                  size: 36,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _controlPlayback('pause'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.stop,
                                  size: 32,
                                  color: Colors.red,
                                ),
                                onPressed: () => _controlPlayback('stop'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.skip_next, size: 32),
                                onPressed: () => _controlPlayback('next'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Volume control
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isMuted ? Icons.volume_off : Icons.volume_up,
                                ),
                                onPressed: () => _toggleMute(),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _currentVolume.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 20,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentVolume = value.round();
                                    });
                                    _setVolume(value.round());
                                  },
                                ),
                              ),
                              Text('${_currentVolume}%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Test Media Section
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Media',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...(_testMediaOptions.map(
                            (media) => Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  _getMediaIcon(media['type'] as String),
                                  color: _getMediaColor(
                                    media['type'] as String,
                                  ),
                                ),
                                title: Text(media['title'] as String),
                                subtitle: Text(media['description'] as String),
                                trailing: ElevatedButton(
                                  onPressed: () => _playSelectedMedia(media),
                                  child: const Text('Play'),
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(height: 16),
                          // Custom URL section
                          const Text(
                            'Play Custom URL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter media URL',
                                    border: OutlineInputBorder(),
                                    hintText: 'https://example.com/media.mp4',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _playCustomUrl,
                                child: const Text('Play'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

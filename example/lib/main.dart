import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'music_player_example.dart';
import 'demo_playlist_viewer.dart';
import 'dlna_connection_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DLNA Media Cast Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainTabView(),
    );
  }
}

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DLNA Media Cast Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.devices),
              text: 'Device Control',
            ),
            Tab(
              icon: Icon(Icons.library_music),
              text: 'Music Player',
            ),
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Demo Info',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DlnaHomePage(),
          MusicPlayerExample(),
          DemoPlaylistViewer(),
        ],
      ),
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
  late final DlnaConnectionManager _connectionManager;
  final TextEditingController _customUrlController = TextEditingController();
  Timer? _playbackPollingTimer;
  Timer? _discoveryPollingTimer;

  @override
  void initState() {
    super.initState();
    _connectionManager = DlnaConnectionManager();
    _connectionManager.addListener(_onConnectionStateChanged);
    initPlatformState();
    _startPlaybackPolling();
    _startDiscoveryPolling();
  }

  void _startPlaybackPolling() {
    _playbackPollingTimer?.cancel();
    _playbackPollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_connectionManager.hasSelectedDevice) {
        try {
          await _connectionManager.updatePlaybackInfo();
          await _connectionManager.updateVolumeInfo(); // Poll volume info as well
        } catch (_) {}
      }
    });
  }

  void _stopPlaybackPolling() {
    _playbackPollingTimer?.cancel();
    _playbackPollingTimer = null;
  }

  void _startDiscoveryPolling() {
    _discoveryPollingTimer?.cancel();
    _discoveryPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        await _connectionManager.updateDiscoveredDevices();
        setState(() {}); // Refresh UI with new devices
      } catch (_) {}
    });
  }

  void _stopDiscoveryPolling() {
    _discoveryPollingTimer?.cancel();
    _discoveryPollingTimer = null;
  }

  void _onConnectionStateChanged() {
    setState(() {
      // Trigger rebuild when connection state changes
    });
    // Start/stop polling based on device selection
    if (_connectionManager.hasSelectedDevice) {
      _startPlaybackPolling();
    } else {
      _stopPlaybackPolling();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // Initialize the UPnP service first
      await _connectionManager.initialize();
      platformVersion = await _connectionManager.controller.getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _startDiscovery() async {
    try {
      await _connectionManager.startDiscovery(timeoutSeconds: 10);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discovery failed: $e')),
      );
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      await _connectionManager.stopDiscovery();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop discovery failed: $e')),
      );
    }
  }

  void _selectRenderer(String rendererUdn) {
    _connectionManager.selectRenderer(rendererUdn);
  }

  void _showDeviceDetails(DlnaDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Device Details'),
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
                _buildDetailRow('Description', device.modelDescription ?? 'No description'),
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
  final List<Map<String, String>> _testMediaOptions = [
    {
      'title': 'Big Buck Bunny (Video)',
      'url': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'type': 'video/mp4',
      'description': 'Open source animated video'
    },
    {
      'title': 'Sample Audio (MP3)',
      'url': 'http://www.soundjay.com/misc/sounds/bell-ringing-05.mp3',
      'type': 'audio/mpeg',
      'description': 'Bell ringing sound'
    },
    {
      'title': 'Sample Image (JPEG)',
      'url': 'https://via.placeholder.com/1920x1080/0000FF/FFFFFF?text=DLNA+Test+Image',
      'type': 'image/jpeg',
      'description': 'Test image placeholder'
    },
  ];

  Future<void> _playSelectedMedia(Map<String, String> media) async {
    if (!_connectionManager.hasSelectedDevice) return;

    final mediaUrl = media['url']!;
    final mediaType = media['type']!;
    final title = media['title']!;
    final description = media['description']!;
    
    // Create appropriate MediaMetadata based on media type
    MediaMetadata metadata;
    if (mediaType.startsWith('video/')) {
      metadata = VideoMetadata(
        description: description,
        duration: null,
        resolution: null,
        thumbnailUri: null,
        genre: null,
        upnpClass: 'object.item.videoItem',
        bitrate: null,
      );
    } else if (mediaType.startsWith('audio/')) {
      metadata = AudioMetadata(
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        genre: null,
        duration: null,
        albumArtUri: null,
        description: description,
        originalTrackNumber: null,
        upnpClass: 'object.item.audioItem',
      );
    } else if (mediaType.startsWith('image/')) {
      metadata = ImageMetadata(
        description: description,
        resolution: null,
        thumbnailUri: null,
        date: null,
        upnpClass: 'object.item.imageItem',
      );
    } else {
      metadata = AudioMetadata(
        artist: 'Unknown',
        album: 'Unknown',
        genre: null,
        duration: null,
        albumArtUri: null,
        description: description,
        originalTrackNumber: null,
        upnpClass: 'object.item',
      );
    }

    try {
      await _connectionManager.playMedia(mediaUrl, metadata: metadata);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing: $title')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Play failed: $e')),
      );
    }
  }


  Future<void> _playCustomUrl() async {
    if (!_connectionManager.hasSelectedDevice || _customUrlController.text.trim().isEmpty) return;

    final url = _customUrlController.text.trim();
    // Use AudioMetadata as a generic fallback for custom URLs
    final metadata = AudioMetadata(
      artist: 'Unknown',
      album: 'Unknown',
      genre: null,
      duration: null,
      albumArtUri: null,
      description: 'Custom Media',
      originalTrackNumber: null,
      upnpClass: 'object.item',
    );

    try {
      await _connectionManager.playMedia(url, metadata: metadata);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playing custom media')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Play failed: $e')),
      );
    }
  }

  Future<void> _controlPlayback(String action) async {
    if (!_connectionManager.hasSelectedDevice) return;

    try {
      await _connectionManager.controlPlayback(action);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action failed: $e')),
      );
    }
  }

  Future<void> _setVolume(int volume) async {
    if (!_connectionManager.hasSelectedDevice) return;

    try {
      await _connectionManager.setVolume(volume);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Set volume failed: $e')),
      );
    }
  }

  Future<void> _toggleMute() async {
    if (!_connectionManager.hasSelectedDevice || _connectionManager.currentVolumeInfo == null) return;

    try {
      await _connectionManager.toggleMute();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toggle mute failed: $e')),
      );
    }
  }

  // Add this method to the _DlnaHomePageState class
  Future<void> _seekToPosition(int positionSeconds) async {
    if (!_connectionManager.hasSelectedDevice || _connectionManager.currentPlaybackInfo == null) return;
    try {
      await _connectionManager.seek(positionSeconds);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seek failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _connectionManager.removeListener(_onConnectionStateChanged);
    _customUrlController.dispose();
    _stopPlaybackPolling();
    _stopDiscoveryPolling();
    super.dispose();
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
                  Text('Discovered devices: ${_connectionManager.discoveredDevices.length}'),
                  if (_connectionManager.selectedRendererUdn != null) ...[
                    const SizedBox(height: 8),
                    Text('Selected renderer: ${_connectionManager.selectedDevice?.friendlyName ?? "Unknown"}'),
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
                    onPressed: _connectionManager.isDiscovering ? null : _startDiscovery,
                    child: Text(_connectionManager.isDiscovering ? 'Discovering...' : 'Start Discovery'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _connectionManager.isDiscovering ? _stopDiscovery : null,
                    child: const Text('Stop Discovery'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _connectionManager.discoveredDevices.isEmpty
                  ? const Center(child: Text('No devices discovered\nTap "Start Discovery" to find DLNA devices'))
                  : ListView.builder(
                      itemCount: _connectionManager.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _connectionManager.discoveredDevices[index];
                        // Use extension method to check if device is a renderer
                        final isRenderer = device.isRenderer;
                        final isSelected = device.udn == _connectionManager.selectedRendererUdn;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              isRenderer ? Icons.tv : Icons.folder,
                              color: isRenderer ? Colors.blue : Colors.orange,
                            ),
                            title: Text(device.friendlyName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${device.manufacturerName} - ${device.modelName}'),
                                Text('Type: ${device.deviceType}'),
                                Text('IP: ${device.ipAddress}:${device.port}'),
                              ],
                            ),
                            trailing: isRenderer
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: isSelected ? null : () => _selectRenderer(device.udn),
                                        child: Text(isSelected ? 'Selected' : 'Select'),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _showDeviceDetails(device),
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
          if (_connectionManager.hasSelectedDevice)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const Divider(),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.music_note, color: Colors.deepPurple, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Playback State: \\${_connectionManager.currentPlaybackInfo!.state.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Position: \\${_connectionManager.currentPlaybackInfo!.position}s / \\${_connectionManager.currentPlaybackInfo!.duration}s',
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          if (_connectionManager.currentPlaybackInfo!.currentTrackUri != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Track: \\${_connectionManager.currentPlaybackInfo!.currentTrackUri}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          // Seek bar
                          if (_connectionManager.currentPlaybackInfo!.duration > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Slider(
                                value: _connectionManager.currentPlaybackInfo!.position.toDouble().clamp(0, _connectionManager.currentPlaybackInfo!.duration.toDouble()),
                                min: 0,
                                max: _connectionManager.currentPlaybackInfo!.duration.toDouble(),
                                activeColor: Colors.deepPurple,
                                inactiveColor: Colors.deepPurple.shade100,
                                onChanged: (value) {
                                  _seekToPosition(value.round());
                                },
                              ),
                            ),
                          // Next/Previous/Play/Pause/Stop controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, size: 32, color: Colors.deepPurple),
                                tooltip: 'Previous',
                                onPressed: () => _controlPlayback('previous'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.play_arrow, size: 36, color: Colors.green),
                                tooltip: 'Play',
                                onPressed: () => _controlPlayback('play'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.pause, size: 36, color: Colors.orange),
                                tooltip: 'Pause',
                                onPressed: () => _controlPlayback('pause'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.stop, size: 32, color: Colors.red),
                                tooltip: 'Stop',
                                onPressed: () => _controlPlayback('stop'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.skip_next, size: 32, color: Colors.deepPurple),
                                tooltip: 'Next',
                                onPressed: () => _controlPlayback('next'),
                              ),
                            ],
                          ),
                          // Volume control row (restored)
                          if (_connectionManager.currentVolumeInfo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _toggleMute,
                                    icon: Icon(_connectionManager.currentVolumeInfo!.muted ? Icons.volume_off : Icons.volume_up, color: Colors.deepPurple),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _connectionManager.currentVolumeInfo!.volume.toDouble(),
                                      min: 0,
                                      max: 100,
                                      divisions: 20,
                                      activeColor: Colors.deepPurple,
                                      onChanged: (value) => _setVolume(value.round()),
                                    ),
                                  ),
                                ],
                              ),
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

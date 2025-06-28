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

  @override
  void initState() {
    super.initState();
    _connectionManager = DlnaConnectionManager();
    _connectionManager.addListener(_onConnectionStateChanged);
    initPlatformState();
  }

  void _onConnectionStateChanged() {
    setState(() {
      // Trigger rebuild when connection state changes
    });
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

  @override
  void dispose() {
    _connectionManager.removeListener(_onConnectionStateChanged);
    _customUrlController.dispose();
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
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
            
            // Discovery controls
            Container(
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

            // Device list
            Container(
              height: 200, // Fixed height for device list
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

            // Playback controls
            if (_connectionManager.hasSelectedDevice) ...[
              const Divider(),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Playback status
                    if (_connectionManager.currentPlaybackInfo != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Playback State: ${_connectionManager.currentPlaybackInfo!.state.name}', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Position: ${_connectionManager.currentPlaybackInfo!.position}s / ${_connectionManager.currentPlaybackInfo!.duration}s'),
                              if (_connectionManager.currentPlaybackInfo!.currentTrackUri != null)
                                Text('Track: ${_connectionManager.currentPlaybackInfo!.currentTrackUri}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Volume controls
                    if (_connectionManager.currentVolumeInfo != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Volume: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${_connectionManager.currentVolumeInfo!.volume}%'),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _toggleMute,
                                    icon: Icon(_connectionManager.currentVolumeInfo!.muted ? Icons.volume_off : Icons.volume_up),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _connectionManager.currentVolumeInfo!.volume.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 20,
                                onChanged: (value) => _setVolume(value.round()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Test media options
                    const Text('Test Media:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._testMediaOptions.map((media) => Card(
                      child: ListTile(
                        title: Text(media['title']!),
                        subtitle: Text(media['description']!),
                        trailing: ElevatedButton(
                          onPressed: () => _playSelectedMedia(media),
                          child: const Text('Play'),
                        ),
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 16),
                    
                    // Custom URL input
                    const Text('Custom Media URL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customUrlController,
                            decoration: const InputDecoration(
                              hintText: 'Enter media URL (http://...)',
                              border: OutlineInputBorder(),
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
                    
                    const SizedBox(height: 16),
                    
                    // Playback control buttons
                    const Text('Playback Controls:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _controlPlayback('play'),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _controlPlayback('pause'),
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _controlPlayback('stop'),
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

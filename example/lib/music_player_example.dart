import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'package:media_cast_dlna/sample_music_playlist.dart';
import 'package:media_cast_dlna/src/media_cast_dlna_pigeon.dart';
import 'dlna_connection_manager.dart';

/// Example of using the sample music playlist with DLNA casting
class MusicPlayerExample extends StatefulWidget {
  const MusicPlayerExample({Key? key}) : super(key: key);

  @override
  State<MusicPlayerExample> createState() => _MusicPlayerExampleState();
}

class _MusicPlayerExampleState extends State<MusicPlayerExample> {
  late final DlnaConnectionManager _connectionManager;
  List<MediaItem> _currentPlaylist = [];
  MediaItem? _currentlyPlaying;
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _connectionManager = DlnaConnectionManager();
    _connectionManager.addListener(_onConnectionStateChanged);
    _initializeDLNA();
    _loadDefaultPlaylist();
  }

  void _onConnectionStateChanged() {
    setState(() {
      // Trigger rebuild when connection state changes
    });
  }
  
  Future<void> _initializeDLNA() async {
    try {
      await _connectionManager.initialize();
    } catch (e) {
      print('Error initializing DLNA: $e');
    }
  }
  
  void _loadDefaultPlaylist() {
    setState(() {
      _currentPlaylist = SampleMusicPlaylist.getSamplePlaylist();
    });
  }
  
  void _loadPlaylistByGenre(String genre) {
    setState(() {
      _currentPlaylist = SampleMusicPlaylist.getPlaylistByGenre(genre);
    });
  }
  
  Future<void> _playMedia(MediaItem mediaItem) async {
    if (!_connectionManager.hasSelectedDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a DLNA device first')),
      );
      return;
    }
    
    try {
      // Set the media URI and play
      await _connectionManager.playMedia(
        mediaItem.uri,
        metadata: mediaItem.metadata!,
      );
      
      setState(() {
        _currentlyPlaying = mediaItem;
        _isPlaying = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing: ${mediaItem.title}')),
      );
    } catch (e) {
      print('Error playing media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing media: $e')),
      );
    }
  }
  
  Future<void> _pausePlayback() async {
    if (_connectionManager.hasSelectedDevice) {
      try {
        await _connectionManager.controlPlayback('pause');
        setState(() {
          _isPlaying = false;
        });
      } catch (e) {
        print('Error pausing: $e');
      }
    }
  }
  
  Future<void> _resumePlayback() async {
    if (_connectionManager.hasSelectedDevice) {
      try {
        await _connectionManager.controlPlayback('play');
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        print('Error resuming: $e');
      }
    }
  }
  
  Future<void> _stopPlayback() async {
    if (_connectionManager.hasSelectedDevice) {
      try {
        await _connectionManager.controlPlayback('stop');
        setState(() {
          _isPlaying = false;
          _currentlyPlaying = null;
        });
      } catch (e) {
        print('Error stopping: $e');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DLNA Music Player'),
        backgroundColor: Colors.deepPurple,
      ),
      body: CustomScrollView(
        slivers: [
          // Device selection
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DLNA Devices:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_connectionManager.discoveredDevices.isEmpty)
                      const Text('No devices found. Make sure your DLNA device is on the same network.')
                    else
                      DropdownButton<DlnaDevice>(
                        value: _connectionManager.selectedDevice,
                        hint: const Text('Select a device'),
                        isExpanded: true,
                        items: _connectionManager.discoveredDevices
                            .where((device) => device.isRenderer)
                            .map((device) {
                          return DropdownMenuItem(
                            value: device,
                            child: Text('${device.friendlyName} (${device.ipAddress})'),
                          );
                        }).toList(),
                        onChanged: (device) {
                          if (device != null) {
                            _connectionManager.selectRenderer(device.udn);
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _connectionManager.isDiscovering ? null : () async {
                              try {
                                await _connectionManager.startDiscovery();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Discovery failed: $e')),
                                );
                              }
                            },
                            child: Text(_connectionManager.isDiscovering ? 'Discovering...' : 'Refresh Devices'),
                          ),
                        ),
                      ],
                    ),
                    if (_connectionManager.hasSelectedDevice) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Connected: ${_connectionManager.selectedDevice!.friendlyName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Currently playing
          if (_currentlyPlaying != null)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Now Playing:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${_currentlyPlaying!.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Text('${(_currentlyPlaying!.metadata as AudioMetadata?)?.artist ?? 'Unknown'}  ${(_currentlyPlaying!.metadata as AudioMetadata?)?.genre ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _stopPlayback,
                            icon: const Icon(Icons.stop),
                          ),
                          IconButton(
                            onPressed: _isPlaying ? _pausePlayback : _resumePlayback,
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Playlist selection
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Playlists:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        _buildPlaylistChip('All Songs', _loadDefaultPlaylist),
                        _buildPlaylistChip('Classical', () => _loadPlaylistByGenre('Classical')),
                        _buildPlaylistChip('Electronic', () => _loadPlaylistByGenre('Electronic')),
                        _buildPlaylistChip('World', () => _loadPlaylistByGenre('World')),
                        _buildPlaylistChip('Ambient', () => _loadPlaylistByGenre('Ambient')),
                        _buildPlaylistChip('8-bit', () => _loadPlaylistByGenre('Chiptune')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Playlist header
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
                child: Text('Playlist (${_currentPlaylist.length} songs):', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          
          // Playlist items as sliver list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _currentPlaylist[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      radius: 16,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(item.title, style: const TextStyle(fontSize: 14)),
                    subtitle: Text('${(item.metadata as AudioMetadata?)?.artist ?? 'Unknown Artist'}  ${(item.metadata as AudioMetadata?)?.genre ?? 'Unknown Genre'}',
                      style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      onPressed: () => _playMedia(item),
                    ),
                    onTap: () => _playMedia(item),
                  ),
                );
              },
              childCount: _currentPlaylist.length,
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
      backgroundColor: Colors.deepPurple.shade50,
    );
  }

  @override
  void dispose() {
    _connectionManager.removeListener(_onConnectionStateChanged);
    super.dispose();
  }
}

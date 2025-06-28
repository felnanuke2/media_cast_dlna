import 'package:flutter/material.dart';
import 'package:media_cast_dlna/sample_music_playlist.dart';
import 'package:media_cast_dlna/src/media_cast_dlna_pigeon.dart';

/// A Flutter widget that displays the demo playlist information in a nice UI
class DemoPlaylistViewer extends StatelessWidget {
  const DemoPlaylistViewer({super.key});

  @override
  Widget build(BuildContext context) {
    final allSongs = SampleMusicPlaylist.getSamplePlaylist();
    
    // Group by genre
    final genres = <String, int>{};
    for (final song in allSongs) {
      final genre = (song.metadata is AudioMetadata) ? (song.metadata as AudioMetadata).genre ?? 'Unknown' : 'Unknown';
      genres[genre] = (genres[genre] ?? 0) + 1;
    }

    // Group by format
    final formats = <String, int>{};
    for (final song in allSongs) {
      final format = song.mimeType.split('/').last.toUpperCase();
      formats[format] = (formats[format] ?? 0) + 1;
    }

    final testPlaylist = SampleMusicPlaylist.getTestPlaylist();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.library_music, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'DLNA Sample Music Playlist',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('📁 Repository: https://github.com/SoundSafari/CC0-1.0-Music'),
                    const Text('📜 License: CC0 1.0 Universal (Public Domain)'),
                    const SizedBox(height: 8),
                    Text('🎧 Total Songs Available: ${allSongs.length}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Genre Distribution
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Songs by Genre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...genres.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Chip(
                            label: Text('${entry.value} songs'),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sample tracks by genre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎼 Sample Tracks by Genre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ..._buildGenreSamples(context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test playlist
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧪 Recommended Test Playlist (${testPlaylist.length} songs)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...testPlaylist.map((song) => ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.title),
                      subtitle: Text('${(song.metadata as AudioMetadata?)?.genre ?? 'Unknown'} - ${song.mimeType}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showSongDetails(context, song),
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // File formats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📁 File Formats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: formats.entries.map((entry) => Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Usage instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Usage Instructions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Import: import \'package:media_cast_dlna/sample_music_playlist.dart\';'),
                    const Text('2. Get songs: SampleMusicPlaylist.getSamplePlaylist()'),
                    const Text('3. Play with DLNA: controller.playMedia(device.udn, song.uri)'),
                    const SizedBox(height: 8),
                    const Text('📖 For complete implementation example, see: example/lib/music_player_example.dart'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✨ All music is completely free to use - no licensing required!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGenreSamples(BuildContext context) {
    final widgets = <Widget>[];

    final drums = SampleMusicPlaylist.getDrumsPlaylist();
    if (drums.isNotEmpty) {
      widgets.add(_buildGenreSection(context, '🥁 All Drum Tracks', drums.take(2).toList()));
    }

    final electronic = SampleMusicPlaylist.getElectronicDrumsPlaylist();
    if (electronic.isNotEmpty) {
      widgets.add(_buildGenreSection(context, '🎧 Electronic Drums', electronic.take(2).toList()));
    }

    final acoustic = SampleMusicPlaylist.getAcousticDrumsPlaylist();
    if (acoustic.isNotEmpty) {
      widgets.add(_buildGenreSection(context, '🪘 Acoustic/World Drums', acoustic.take(2).toList()));
    }

    final studio = SampleMusicPlaylist.getStudioDrumsPlaylist();
    if (studio.isNotEmpty) {
      widgets.add(_buildGenreSection(context, '🏢 Studio Drum Tracks', studio.take(2).toList()));
    }

    return widgets;
  }

  Widget _buildGenreSection(BuildContext context, String title, List<MediaItem> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...songs.map((song) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${song.title} by ${(song.metadata as AudioMetadata?)?.artist ?? 'Unknown Artist'}'),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showSongDetails(BuildContext context, MediaItem song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Artist', (song.metadata as AudioMetadata?)?.artist ?? 'Unknown Artist'),
            _buildDetailRow('Genre', (song.metadata as AudioMetadata?)?.genre ?? 'Unknown'),
            _buildDetailRow('Format', song.mimeType),
            _buildDetailRow('Duration', (song.metadata as AudioMetadata?)?.duration?.toString() ?? 'Unknown'),
            const SizedBox(height: 8),
            const Text('URL:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(
              song.uri,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

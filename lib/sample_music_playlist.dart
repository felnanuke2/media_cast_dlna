import 'package:media_cast_dlna/src/media_cast_dlna_pigeon.dart';

/// Sample playlist using various drum tracks for testing
/// These tracks are freely available for testing DLNA casting functionality
class SampleMusicPlaylist {
  
  /// Sample playlist using drum tracks from various sources
  /// These tracks are freely available and suitable for testing purposes
  static List<MediaItem> getSamplePlaylist() {
    final tracksReference = getDrumTracksReference();
    return tracksReference.map((track) => MediaItem(
      id: track['id']!,
      title: track['title']!,
      uri: track['uri']!,
      mimeType: 'audio/mpeg',
      metadata: AudioMetadata(
        artist: 'Various Artists',
        album: 'Drum Tracks Collection',
        genre: track['genre'],
        description: track['description'],
      ),
    )).toList();
  }
  
  /// Get playlist by genre
  static List<MediaItem> getPlaylistByGenre(String genre) {
    final allSongs = getSamplePlaylist();
    return allSongs.where((song) => (song.metadata is AudioMetadata) && (song.metadata as AudioMetadata).genre?.toLowerCase() == genre.toLowerCase()).toList();
  }
  
  /// Get drum tracks playlist (all tracks are drums)
  static List<MediaItem> getDrumsPlaylist() {
    return getPlaylistByGenre('Drums');
  }
  
  /// Get electronic drum tracks
  static List<MediaItem> getElectronicDrumsPlaylist() {
    final allSongs = getSamplePlaylist();
    return allSongs.where((song) => 
      (song.metadata is AudioMetadata) && (
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('electronic') == true ||
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('trigger') == true ||
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('ez drummer') == true
      )
    ).toList();
  }
  
  /// Get acoustic drum tracks
  static List<MediaItem> getAcousticDrumsPlaylist() {
    final allSongs = getSamplePlaylist();
    return allSongs.where((song) => 
      (song.metadata is AudioMetadata) && (
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('djembe') == true ||
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('carnival') == true ||
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('mardi gras') == true
      )
    ).toList();
  }
  
  /// Get professional studio drum tracks
  static List<MediaItem> getStudioDrumsPlaylist() {
    final allSongs = getSamplePlaylist();
    return allSongs.where((song) => 
      (song.metadata is AudioMetadata) && (
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('professional') == true ||
        (song.metadata as AudioMetadata).description?.toLowerCase().contains('studio') == true
      )
    ).toList();
  }
  
  /// Get a random subset of songs from the full playlist
  static List<MediaItem> getRandomPlaylist(int count) {
    final allSongs = getSamplePlaylist();
    final shuffled = List<MediaItem>.from(allSongs)..shuffle();
    return shuffled.take(count).toList();
  }
  
  /// Get music suitable for testing DLNA casting
  static List<MediaItem> getTestPlaylist() {
    return [
      getSamplePlaylist()[0], // Carnival - clear drum track
      getSamplePlaylist()[1], // 104 Samples - electronic samples
      getSamplePlaylist()[4], // ORLP32 6 - professional quality
      getSamplePlaylist()[8], // Mardi Gras - stereo percussion
    ];
  }
  
  /// Sample drum tracks from various sources
  /// These tracks are freely available for testing purposes
  static List<Map<String, String>> getDrumTracksReference() {
    return [
      {
        'id': 'drum_track_001',
        'title': 'Carnival',
        'uri': 'http://www.phatdrumloops.com/audio/adpcm/carnival.wav',
        'duration': '3.9',
        'keywords': 'drum track, carnival, percussion',
        'genre': 'Drums',
        'description': 'Carnival drum track - 21k, mono, 8-bit, 11025 Hz',
        'format': '21k, mono, 8-bit, 11025 Hz',
      },
      {
        'id': 'drum_track_002',
        'title': '104 Samples',
        'uri': 'http://ladik.ladik.eu/wp-content/uploads/2015/06/104.mp3',
        'duration': '6.5',
        'keywords': 'drum track, samples, electronic',
        'genre': 'Drums',
        'description': 'Drum track with samples - 103k, mono, 16-bit, 44100 Hz',
        'format': '103k, mono, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_003',
        'title': 'Kuku Djembe',
        'uri': 'http://laurent.cambon.free.fr/SONS/Kuku1.WAV',
        'duration': '2.3',
        'keywords': 'djembe, drum track, african percussion',
        'genre': 'Drums',
        'description': 'Djembe drum track - 49k, mono, 8-bit, 22050 Hz',
        'format': '49k, mono, 8-bit, 22050 Hz',
      },
      {
        'id': 'drum_track_004',
        'title': 'Trigger Only',
        'uri': 'http://blankfield.but.jp/wordpress/wp-content/uploads/2016/06/trigger_only.wav',
        'duration': '7.6',
        'keywords': 'drum track, trigger, electronic drums',
        'genre': 'Drums',
        'description': 'Electronic drum trigger track - 1301k, stereo, 16-bit, 44100 Hz',
        'format': '1301k, stereo, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_005',
        'title': 'ORLP32 6',
        'uri': 'http://demo3.bigfishaudio.net/demo/orlp32_6.mp3',
        'duration': '4.2',
        'keywords': 'drum track, professional, studio quality',
        'genre': 'Drums',
        'description': 'Professional drum track 6 - 168k, stereo, 16-bit, 44100 Hz',
        'format': '168k, stereo, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_006',
        'title': 'ORLP32 9',
        'uri': 'http://demo3.bigfishaudio.net/demo/orlp32_9.mp3',
        'duration': '4.2',
        'keywords': 'drum track, professional, studio quality',
        'genre': 'Drums',
        'description': 'Professional drum track 9 - 168k, stereo, 16-bit, 44100 Hz',
        'format': '168k, stereo, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_007',
        'title': '102 Samples',
        'uri': 'http://ladik.ladik.eu/wp-content/uploads/2015/06/102.mp3',
        'duration': '6.4',
        'keywords': 'drum track, samples, electronic',
        'genre': 'Drums',
        'description': 'Drum track with samples - 101k, mono, 16-bit, 44100 Hz',
        'format': '101k, mono, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_008',
        'title': 'ORLP32 11',
        'uri': 'http://demo3.bigfishaudio.net/demo/orlp32_11.mp3',
        'duration': '4.1',
        'keywords': 'drum track, professional, studio quality',
        'genre': 'Drums',
        'description': 'Professional drum track 11 - 162k, stereo, 16-bit, 44100 Hz',
        'format': '162k, stereo, 16-bit, 44100 Hz',
      },
      {
        'id': 'drum_track_009',
        'title': 'Mardi Gras',
        'uri': 'http://www.phatdrumloops.com/audio/wav/mardigras1.wav',
        'duration': '5.4',
        'keywords': 'drum track, mardi gras, celebration, percussion',
        'genre': 'Drums',
        'description': 'Mardi Gras drum track - 233k, stereo, 16-bit, 11025 Hz',
        'format': '233k, stereo, 16-bit, 11025 Hz',
      },
      {
        'id': 'drum_track_010',
        'title': 'EZ Only',
        'uri': 'http://blankfield.but.jp/wordpress/wp-content/uploads/2016/06/ez_only.wav',
        'duration': '7.6',
        'keywords': 'drum track, ez drummer, electronic drums',
        'genre': 'Drums',
        'description': 'EZ drummer track - 1301k, stereo, 16-bit, 44100 Hz',
        'format': '1301k, stereo, 16-bit, 44100 Hz',
      },
    ];
  }
  
  /// Create MediaItem objects for drum tracks when hosted locally
  /// Users can host these tracks on their own servers if needed
  static List<MediaItem> createDrumTracksPlaylist(String baseHostingUrl) {
    final tracksReference = getDrumTracksReference();
    return tracksReference.map((track) => MediaItem(
      id: track['id']!,
      title: track['title']!,
      uri: '$baseHostingUrl/${track['title']!.toLowerCase().replaceAll(' ', '_')}.wav',
      mimeType: 'audio/wav',
      metadata: AudioMetadata(
        artist: 'Various Artists',
        album: 'Drum Tracks Collection',
        genre: track['genre'],
        description: track['description'],
      ),
    )).toList();
  }
}

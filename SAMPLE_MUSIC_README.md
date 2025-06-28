# Sample Music Playlist for DLNA Media Casting

This project includes a curated playlist of **CC0-1.0 licensed music** from [freesound.org](https://freesound.org) that you can use freely in your DLNA media casting application. All songs are royalty-free and can be used without any licensing restrictions.

## 🎵 What's Included

The sample playlist includes **17 carefully selected tracks** across various genres:

### 🎼 Classical & Piano
- Piano Pling - A beautiful clear piano note
- Gentle Music Box - Peaceful music box melody  
- Music Box Lullaby - Soothing lullaby melody
- Beautiful Violin Music - Melodic violin piece
- Slow Dramatic Orchestra - Dramatic orchestral composition

### 🎸 Folk & Guitar
- Ukulele - Acoustic ukulele melody
- Guitar Strumming - Acoustic guitar patterns
- Melodic Guitar - Electric guitar piece
- Harmonica - Traditional harmonica melody

### 🎧 Electronic & Ambient
- Chill Music - Relaxing electronic music
- Cosmic Glow - Cosmic ambient soundscape
- Simple Loopable Beat - Electronic drum loop
- Hip Hop Beat Chill - Laid-back hip hop beat

### 🌍 World Music
- Chinese Flute Hulusi - Traditional Chinese wind instrument
- Moroccan Guimbri Lute - Traditional Moroccan string instrument

### 🎮 8-bit/Chiptune
- Pixel Song 1 & 2 - Retro 8-bit style music

## 🚀 How to Use

### 1. Import the Playlist
```dart
import 'package:media_cast_dlna/sample_music_playlist.dart';
```

### 2. Get the Full Playlist
```dart
List<MediaItem> songs = SampleMusicPlaylist.getSamplePlaylist();
```

### 3. Get Playlists by Genre
```dart
// Get classical music only
List<MediaItem> classical = SampleMusicPlaylist.getClassicalPlaylist();

// Get electronic music only
List<MediaItem> electronic = SampleMusicPlaylist.getElectronicPlaylist();

// Get world music only
List<MediaItem> worldMusic = SampleMusicPlaylist.getWorldMusicPlaylist();

// Get ambient music only
List<MediaItem> ambient = SampleMusicPlaylist.getAmbientPlaylist();

// Get chiptune music only
List<MediaItem> chiptune = SampleMusicPlaylist.getChiptunePlaylist();
```

### 4. Get Random Selection
```dart
// Get 5 random songs
List<MediaItem> randomSongs = SampleMusicPlaylist.getRandomPlaylist(5);
```

### 5. Get Test Playlist
```dart
// Get a small playlist perfect for testing DLNA functionality
List<MediaItem> testSongs = SampleMusicPlaylist.getTestPlaylist();
```

## 📱 Example Implementation

Check out the complete example in `example/lib/music_player_example.dart` to see:

- How to initialize DLNA service
- How to discover DLNA devices on your network
- How to play the sample songs on DLNA devices
- How to control playback (play, pause, stop)
- How to switch between different genre playlists

### Key Features of the Example:
- **Device Discovery**: Automatically find DLNA devices on your network
- **Genre Filtering**: Filter songs by Classical, Electronic, World Music, Ambient, or 8-bit
- **Playback Control**: Play, pause, and stop functionality
- **Now Playing**: Display current track information
- **User-Friendly UI**: Clean, intuitive interface

## 🔧 Technical Details

### File Formats Supported
- **WAV** - Uncompressed audio (highest quality)
- **MP3** - Compressed audio (smaller file size)
- **AIFF** - Apple's audio format
- **FLAC** - Lossless compression

### Network Requirements
- Your device and DLNA renderer must be on the **same WiFi network**
- DLNA/UPnP must be enabled on your target device
- No special firewall configuration required for most home networks

### Sample MediaItem Structure
```dart
MediaItem(
  id: 'unique_id',
  title: 'Song Title',
  uri: 'https://raw.githubusercontent.com/SoundSafari/CC0-1.0-Music/main/freesound.org/filename.wav',
  mimeType: 'audio/wav',
  artist: 'Artist Name',
  album: 'Freesound Collection',
  genre: 'Genre',
  description: 'Song description',
)
```

## 📜 License Information

All music files are licensed under **CC0 1.0 Universal (CC0 1.0) Public Domain Dedication**.

This means:
- ✅ **Free to use** for any purpose
- ✅ **No attribution required** (though appreciated)
- ✅ **Commercial use allowed**
- ✅ **Modify and redistribute freely**
- ✅ **No licensing fees ever**

## 🎯 Perfect for Testing

This playlist is ideal for:
- **Testing DLNA functionality** - Variety of formats and genres
- **Demo applications** - Professional-quality music
- **Development** - No licensing concerns
- **Prototyping** - Quick access to diverse audio content

## 🌐 Source

All tracks are sourced from the **CC0-1.0-Music** repository:
- **Repository**: [SoundSafari/CC0-1.0-Music](https://github.com/SoundSafari/CC0-1.0-Music)
- **Original Source**: [freesound.org](https://freesound.org)
- **License**: CC0 1.0 Universal

## 🔄 Extending the Playlist

Want to add more songs? You can:

1. Browse the [full repository](https://github.com/SoundSafari/CC0-1.0-Music/tree/main/freesound.org) (2000+ files!)
2. Add new `MediaItem` entries to the playlist
3. Create custom playlists for your specific needs
4. Filter by different criteria (duration, file size, etc.)

The repository contains thousands of additional CC0-licensed audio files ready for use!

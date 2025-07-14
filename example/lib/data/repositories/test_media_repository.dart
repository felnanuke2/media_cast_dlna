import '../../core/models/app_models.dart';

/// Repository providing test media items
class TestMediaRepository {
  static List<TestMediaItem> getTestMediaItems() {
    return [
      const TestMediaItem(
        title: 'Big Buck Bunny (Video)',
        url:
            'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        type: 'video/mp4',
        description: 'Open source 3D computer-animated comedy short film',
        thumbnailUri:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
        duration: 596, // 9:56
      ),
      const TestMediaItem(
        title: 'Sintel Trailer (Video)',
        url:
            'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        type: 'video/mp4',
        description: 'Blender Foundation\'s third open movie',
        thumbnailUri:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
        duration: 888, // 14:48
      ),
      const TestMediaItem(
        title: 'Kalimba (Audio)',
        url:
            'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3',
        type: 'audio/mpeg',
        description: 'Sample audio file for testing',
        artist: 'Mr. Scruff',
        album: 'Sample Music',
        thumbnailUri: 'https://picsum.photos/1920/1080',
        genre: 'Electronic',
        duration: 330, // 5:30
      ),
      const TestMediaItem(
        title: 'Sample Image',
        url: 'https://picsum.photos/1920/1080',
        type: 'image/jpeg',
        description: 'Sample image for testing image display',
        resolution: '1920x1080',
      ),
    ];
  }

  TestMediaRepository._();
}

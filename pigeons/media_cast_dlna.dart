import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/media_cast_dlna_pigeon.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/br/com/felnanuke2/media_cast_dlna/MediaCastDlnaPigeon.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Classes/MediaCastDlnaPigeon.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'media_cast_dlna',
))

/// Represents a UPnP/DLNA device discovered on the network
class DlnaDevice {
  DlnaDevice({
    required this.udn,
    required this.friendlyName,
    required this.deviceType,
    required this.manufacturerName,
    required this.modelName,
    required this.ipAddress,
    required this.port,
    this.modelDescription,
    this.presentationUrl,
    this.iconUrl,
  });

  /// Unique Device Name
  final String udn;
  
  /// Human-readable device name
  final String friendlyName;
  
  /// Device type (e.g., MediaRenderer, MediaServer)
  final String deviceType;
  
  /// Manufacturer name
  final String manufacturerName;
  
  /// Model name
  final String modelName;
  
  /// Device IP address
  final String ipAddress;
  
  /// Device port
  final int port;
  
  /// Optional model description
  final String? modelDescription;
  
  /// Optional presentation URL
  final String? presentationUrl;
  
  /// Optional icon URL
  final String? iconUrl;
}

/// Represents a UPnP service available on a device
class DlnaService {
  DlnaService({
    required this.serviceType,
    required this.serviceId,
    required this.scpdUrl,
    required this.controlUrl,
    required this.eventSubUrl,
  });

  /// Service type (e.g., AVTransport, RenderingControl, ContentDirectory)
  final String serviceType;
  
  /// Service ID
  final String serviceId;
  
  /// Service Control Protocol Description URL
  final String scpdUrl;
  
  /// Control URL for actions
  final String controlUrl;
  
  /// Event subscription URL
  final String eventSubUrl;
}

/// Represents media content that can be played
class MediaItem {
  MediaItem({
    required this.id,
    required this.title,
    required this.uri,
    required this.mimeType,
    this.metadata,
    this.size,
  });

  /// Content ID
  final String id;
  
  /// Content title
  final String title;
  
  /// Content URI
  final String uri;
  
  /// MIME type
  final String mimeType;
  
  /// Structured metadata (audio, video, image)
  final MediaMetadata? metadata;
  
  /// File size in bytes
  final int? size;
}

/// Abstract class for media metadata
sealed class MediaMetadata {}

/// Audio-specific metadata
class AudioMetadata extends MediaMetadata {
  AudioMetadata({
    this.artist,
    this.album,
    this.genre,
    this.duration,
    this.albumArtUri,
    this.description,
    this.originalTrackNumber,
    this.upnpClass,
  });

  final String? artist;
  final String? album;
  final String? genre;
  final int? duration;
  final String? albumArtUri;
  final String? description;
  final int? originalTrackNumber;
  final String? upnpClass;
}

/// Video-specific metadata
class VideoMetadata extends MediaMetadata {
  VideoMetadata({
    this.resolution,
    this.duration,
    this.description,
    this.thumbnailUri,
    this.genre,
    this.upnpClass,
    this.bitrate,
  });

  final String? resolution;
  final int? duration;
  final String? description;
  final String? thumbnailUri;
  final String? genre;
  final String? upnpClass;
  final int? bitrate;
}

/// Image-specific metadata
class ImageMetadata extends MediaMetadata {
  ImageMetadata({
    this.resolution,
    this.description,
    this.thumbnailUri,
    this.date,
    this.upnpClass,
  });

  final String? resolution;
  final String? description;
  final String? thumbnailUri;
  final String? date;
  final String? upnpClass;
}

/// Represents the current transport state
enum TransportState {
  stopped,
  playing,
  paused,
  transitioning,
  noMediaPresent,
}

/// Represents playback information
class PlaybackInfo {
  PlaybackInfo({
    required this.state,
    required this.position,
    required this.duration,
    this.currentTrackUri,
    this.currentTrackMetadata,
  });

  /// Current transport state
  final TransportState state;
  
  /// Current position in seconds
  final int position;
  
  /// Total duration in seconds
  final int duration;
  
  /// Current track URI
  final String? currentTrackUri;
  
  /// Current track metadata
  final String? currentTrackMetadata;
}

/// Volume information
class VolumeInfo {
  VolumeInfo({
    required this.volume,
    required this.muted,
  });

  /// Volume level (0-100)
  final int volume;
  
  /// Whether audio is muted
  final bool muted;
}

/// Discovery options
class DiscoveryOptions {
  DiscoveryOptions({
    this.searchTarget,
    this.timeout = 5,
  });

  /// Search target (ST header) - can be "upnp:rootdevice", "ssdp:all", or specific device type
  final String? searchTarget;
  
  /// Discovery timeout in seconds
  final int timeout;
}

/// Host API for device discovery and control
@HostApi()
abstract class MediaCastDlnaApi {
  
  // ==== Initialization ====
  
  /// Initialize the UPnP service and prepare for device discovery/control
  /// This must be called before any other operations
  void initializeUpnpService();
  
  /// Check if UPnP service is initialized and ready
  bool isUpnpServiceInitialized();
  
  /// Shutdown and cleanup UPnP service
  void shutdownUpnpService();
  
  // ==== Discovery Methods ====
  
  /// Start UPnP/DLNA device discovery
  /// Returns immediately, devices are reported via the DeviceDiscoveryApi callback
  /// Note: initializeUpnpService() must be called first
  void startDiscovery(DiscoveryOptions options);
  
  /// Stop device discovery
  void stopDiscovery();
  
  /// Get list of currently discovered devices
  List<DlnaDevice> getDiscoveredDevices();
  
  /// Refresh device information
  DlnaDevice? refreshDevice(String deviceUdn);
  
  // ==== Device Services ====
  
  /// Get services available on a device
  List<DlnaService> getDeviceServices(String deviceUdn);
  
  /// Check if device supports a specific service type
  bool hasService(String deviceUdn, String serviceType);
  
  // ==== Media Server Methods ====
  
  /// Browse content directory of a media server
  /// parentId: ID of the container to browse (use "0" for root)
  /// startIndex: Starting index for pagination
  /// requestCount: Number of items to request
  List<MediaItem> browseContentDirectory(
    String deviceUdn, 
    String parentId, 
    int startIndex, 
    int requestCount
  );
  
  /// Search content directory
  List<MediaItem> searchContentDirectory(
    String deviceUdn,
    String containerId,
    String searchCriteria,
    int startIndex,
    int requestCount
  );
  
  // ==== Media Renderer Control ====
  
  /// Set the media URI to play on a renderer
  void setMediaUri(String deviceUdn, String uri, MediaMetadata metadata);
  
  /// Start playback
  void play(String deviceUdn);
  
  /// Pause playback
  void pause(String deviceUdn);
  
  /// Stop playback
  void stop(String deviceUdn);
  
  /// Seek to specific position (in seconds)
  void seek(String deviceUdn, int positionSeconds);
  
  /// Skip to next track
  void next(String deviceUdn);
  
  /// Skip to previous track
  void previous(String deviceUdn);
  
  // ==== Volume Control ====
  
  /// Set volume (0-100)
  void setVolume(String deviceUdn, int volume);
  
  /// Get current volume info
  VolumeInfo getVolumeInfo(String deviceUdn);
  
  /// Mute/unmute audio
  void setMute(String deviceUdn, bool muted);
  
  // ==== Playback Status ====
  
  /// Get current playback information
  PlaybackInfo getPlaybackInfo(String deviceUdn);
  
  /// Get current position info
  int getCurrentPosition(String deviceUdn);
  
  /// Get transport state
  TransportState getTransportState(String deviceUdn);
  
  // ==== Subscription Management ====
  
  /// Subscribe to device events (transport state changes, volume changes, etc.)
  void subscribeToEvents(String deviceUdn, String serviceType);
  
  /// Unsubscribe from device events
  void unsubscribeFromEvents(String deviceUdn, String serviceType);
  
  // ==== Utility Methods ====
  
  /// Get platform version
  String getPlatformVersion();
  
  /// Check if UPnP is available on the platform
  bool isUpnpAvailable();
  
  /// Get network interface information
  List<String> getNetworkInterfaces();
}

/// Flutter API for receiving callbacks from native platform
@FlutterApi()
abstract class DeviceDiscoveryApi {
  
  /// Called when a new device is discovered
  void onDeviceDiscovered(DlnaDevice device);
  
  /// Called when a device is removed/lost
  void onDeviceRemoved(DlnaDevice deviceUdn);
  
  /// Called when a device is updated
  void onDeviceUpdated(DlnaDevice device);
  
  /// Called when discovery encounters an error
  void onDiscoveryError(String error);
  
  /// Called when discovery is completed
  void onDiscoveryCompleted();
}

/// Flutter API for receiving media renderer events
@FlutterApi()
abstract class MediaRendererEventsApi {
  
  /// Called when transport state changes
  void onTransportStateChanged(String deviceUdn, TransportState state);
  
  /// Called when position changes during playback
  void onPositionChanged(String deviceUdn, int positionSeconds);
  
  /// Called when volume changes
  void onVolumeChanged(String deviceUdn, VolumeInfo volumeInfo);
  
  /// Called when current track changes
  void onTrackChanged(String deviceUdn, String? trackUri, String? trackMetadata);
  
  /// Called when an error occurs during playback
  void onPlaybackError(String deviceUdn, String error);
}

/// Flutter API for receiving media server events
@FlutterApi()
abstract class MediaServerEventsApi {
  
  /// Called when content directory is updated
  void onContentDirectoryUpdated(String deviceUdn, String containerId);
  
  /// Called when a content directory operation encounters an error
  void onContentDirectoryError(String deviceUdn, String error);
}

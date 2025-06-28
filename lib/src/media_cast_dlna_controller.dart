import 'dart:async';
import 'media_cast_dlna_pigeon.dart';

/// Main controller class for DLNA media casting operations
class MediaCastDlnaController {
  static MediaCastDlnaController? _instance;
  late final MediaCastDlnaApi _api;
  late final DeviceDiscoveryApi _deviceDiscoveryApi;
  late final MediaRendererEventsApi _rendererEventsApi;
  late final MediaServerEventsApi _serverEventsApi;

  // Stream controllers for events
  final _deviceDiscoveredController = StreamController<DlnaDevice>.broadcast();
  final _deviceRemovedController = StreamController<DlnaDevice>.broadcast();
  final _deviceUpdatedController = StreamController<DlnaDevice>.broadcast();
  final _discoveryErrorController = StreamController<String>.broadcast();
  final _discoveryCompletedController = StreamController<void>.broadcast();

  final _transportStateChangedController =
      StreamController<({String deviceUdn, TransportState state})>.broadcast();
  final _positionChangedController =
      StreamController<({String deviceUdn, int positionSeconds})>.broadcast();
  final _volumeChangedController =
      StreamController<({String deviceUdn, VolumeInfo volumeInfo})>.broadcast();
  final _trackChangedController =
      StreamController<
        ({String deviceUdn, String? trackUri, String? trackMetadata})
      >.broadcast();
  final _playbackErrorController =
      StreamController<({String deviceUdn, String error})>.broadcast();

  final _contentDirectoryUpdatedController =
      StreamController<({String deviceUdn, String containerId})>.broadcast();
  final _contentDirectoryErrorController =
      StreamController<({String deviceUdn, String error})>.broadcast();

  MediaCastDlnaController._internal() {
    _api = MediaCastDlnaApi();
    _setupCallbacks();
  }

  /// Get singleton instance of the controller
  static MediaCastDlnaController get instance {
    _instance ??= MediaCastDlnaController._internal();
    return _instance!;
  }

  void _setupCallbacks() {
    _deviceDiscoveryApi = _DeviceDiscoveryApiImpl(this);
    _rendererEventsApi = _MediaRendererEventsApiImpl(this);
    _serverEventsApi = _MediaServerEventsApiImpl(this);

    DeviceDiscoveryApi.setUp(_deviceDiscoveryApi);
    MediaRendererEventsApi.setUp(_rendererEventsApi);
    MediaServerEventsApi.setUp(_serverEventsApi);
  }

  // Getters for event streams

  /// Stream of discovered devices
  Stream<DlnaDevice> get onDeviceDiscovered =>
      _deviceDiscoveredController.stream;

  /// Stream of removed device UDNs
  Stream<DlnaDevice> get onDeviceRemoved => _deviceRemovedController.stream;

  /// Stream of updated devices
  Stream<DlnaDevice> get onDeviceUpdated => _deviceUpdatedController.stream;

  /// Stream of discovery errors
  Stream<String> get onDiscoveryError => _discoveryErrorController.stream;

  /// Stream indicating discovery completion
  Stream<void> get onDiscoveryCompleted => _discoveryCompletedController.stream;

  /// Stream of transport state changes
  Stream<({String deviceUdn, TransportState state})>
  get onTransportStateChanged => _transportStateChangedController.stream;

  /// Stream of position changes during playback
  Stream<({String deviceUdn, int positionSeconds})> get onPositionChanged =>
      _positionChangedController.stream;

  /// Stream of volume changes
  Stream<({String deviceUdn, VolumeInfo volumeInfo})> get onVolumeChanged =>
      _volumeChangedController.stream;

  /// Stream of track changes
  Stream<({String deviceUdn, String? trackUri, String? trackMetadata})>
  get onTrackChanged => _trackChangedController.stream;

  /// Stream of playback errors
  Stream<({String deviceUdn, String error})> get onPlaybackError =>
      _playbackErrorController.stream;

  /// Stream of content directory updates
  Stream<({String deviceUdn, String containerId})>
  get onContentDirectoryUpdated => _contentDirectoryUpdatedController.stream;

  /// Stream of content directory errors
  Stream<({String deviceUdn, String error})> get onContentDirectoryError =>
      _contentDirectoryErrorController.stream;

  // Initialization methods

  /// Initialize the UPnP service and prepare for device discovery/control
  /// This must be called before any other operations
  Future<void> initializeUpnpService() async {
    await _api.initializeUpnpService();
  }

  /// Check if UPnP service is initialized and ready
  Future<bool> isUpnpServiceInitialized() async {
    return await _api.isUpnpServiceInitialized();
  }

  // Discovery methods

  /// Start discovering DLNA devices on the network
  Future<void> startDiscovery({
    String? searchTarget,
    int timeoutSeconds = 5,
  }) async {
    final options = DiscoveryOptions(
      searchTarget: searchTarget,
      timeout: timeoutSeconds,
    );
    await _api.startDiscovery(options);
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    await _api.stopDiscovery();
  }

  /// Get list of currently discovered devices
  Future<List<DlnaDevice>> getDiscoveredDevices() async {
    return await _api.getDiscoveredDevices();
  }

  /// Get media renderer devices (devices that can play media)
  Future<List<DlnaDevice>> getMediaRenderers() async {
    final devices = await getDiscoveredDevices();
    return devices
        .where(
          (device) =>
              device.deviceType.contains('MediaRenderer') ||
              device.deviceType.contains('mediarenderer'),
        )
        .toList();
  }

  /// Get media server devices (devices that serve media content)
  Future<List<DlnaDevice>> getMediaServers() async {
    final devices = await getDiscoveredDevices();
    return devices
        .where(
          (device) =>
              device.deviceType.contains('MediaServer') ||
              device.deviceType.contains('mediaserver'),
        )
        .toList();
  }

  /// Refresh information for a specific device
  Future<DlnaDevice?> refreshDevice(String deviceUdn) async {
    return await _api.refreshDevice(deviceUdn);
  }

  // Device service methods

  /// Get services available on a device
  Future<List<DlnaService>> getDeviceServices(String deviceUdn) async {
    return await _api.getDeviceServices(deviceUdn);
  }

  /// Check if device supports a specific service type
  Future<bool> hasService(String deviceUdn, String serviceType) async {
    return await _api.hasService(deviceUdn, serviceType);
  }

  // Media server methods

  /// Browse content directory of a media server
  Future<List<MediaItem>> browseContent(
    String serverUdn, {
    String parentId = "0",
    int startIndex = 0,
    int count = 100,
  }) async {
    return await _api.browseContentDirectory(
      serverUdn,
      parentId,
      startIndex,
      count,
    );
  }

  /// Search content directory
  Future<List<MediaItem>> searchContent(
    String serverUdn,
    String searchCriteria, {
    String containerId = "0",
    int startIndex = 0,
    int count = 100,
  }) async {
    return await _api.searchContentDirectory(
      serverUdn,
      containerId,
      searchCriteria,
      startIndex,
      count,
    );
  }

  // Media renderer control methods

  /// Play media on a renderer device
  Future<void> playMedia(
    String rendererUdn,
    String mediaUri, {
    required MediaMetadata metadata,
  }) async {
    await _api.setMediaUri(rendererUdn, mediaUri, metadata);
    await _api.play(rendererUdn);
  }

  /// Set media URI without starting playback
  Future<void> setMediaUri(
    String rendererUdn,
    String uri,
    MediaMetadata metadata,
  ) async {
    await _api.setMediaUri(rendererUdn, uri, metadata);
  }

  /// Start playback
  Future<void> play(String rendererUdn) async {
    await _api.play(rendererUdn);
  }

  /// Pause playback
  Future<void> pause(String rendererUdn) async {
    final state = await getTransportState(rendererUdn);
    if (state == TransportState.playing) {
      await _api.pause(rendererUdn);
    } else {
      throw StateError('Cannot pause: Device is not in PLAYING state (current: $state)');
    }
  }

  /// Stop playback
  Future<void> stop(String rendererUdn) async {
    await _api.stop(rendererUdn);
  }

  /// Seek to specific position
  Future<void> seek(String rendererUdn, Duration position) async {
    await _api.seek(rendererUdn, position.inSeconds);
  }

  /// Skip to next track
  Future<void> next(String rendererUdn) async {
    await _api.next(rendererUdn);
  }

  /// Skip to previous track
  Future<void> previous(String rendererUdn) async {
    await _api.previous(rendererUdn);
  }

  // Volume control methods

  /// Set volume (0-100)
  Future<void> setVolume(String rendererUdn, int volume) async {
    await _api.setVolume(rendererUdn, volume.clamp(0, 100));
  }

  /// Get current volume information
  Future<VolumeInfo> getVolumeInfo(String rendererUdn) async {
    return await _api.getVolumeInfo(rendererUdn);
  }

  /// Mute or unmute audio
  Future<void> setMute(String rendererUdn, bool muted) async {
    await _api.setMute(rendererUdn, muted);
  }

  // Playback status methods

  /// Get current playback information
  Future<PlaybackInfo> getPlaybackInfo(String rendererUdn) async {
    return await _api.getPlaybackInfo(rendererUdn);
  }

  /// Get current playback position
  Future<Duration> getCurrentPosition(String rendererUdn) async {
    final seconds = await _api.getCurrentPosition(rendererUdn);
    return Duration(seconds: seconds);
  }

  /// Get transport state
  Future<TransportState> getTransportState(String rendererUdn) async {
    return await _api.getTransportState(rendererUdn);
  }

  // Event subscription methods

  /// Subscribe to device events
  Future<void> subscribeToEvents(String deviceUdn, String serviceType) async {
    await _api.subscribeToEvents(deviceUdn, serviceType);
  }

  /// Unsubscribe from device events
  Future<void> unsubscribeFromEvents(
    String deviceUdn,
    String serviceType,
  ) async {
    await _api.unsubscribeFromEvents(deviceUdn, serviceType);
  }

  /// Subscribe to all common renderer events
  Future<void> subscribeToRendererEvents(String rendererUdn) async {
    await subscribeToEvents(
      rendererUdn,
      'urn:schemas-upnp-org:service:AVTransport:1',
    );
    await subscribeToEvents(
      rendererUdn,
      'urn:schemas-upnp-org:service:RenderingControl:1',
    );
  }

  /// Subscribe to media server events
  Future<void> subscribeToServerEvents(String serverUdn) async {
    await subscribeToEvents(
      serverUdn,
      'urn:schemas-upnp-org:service:ContentDirectory:1',
    );
  }

  // Utility methods

  /// Get platform version
  Future<String> getPlatformVersion() async {
    return await _api.getPlatformVersion();
  }

  /// Check if UPnP is available on the platform
  Future<bool> isUpnpAvailable() async {
    return await _api.isUpnpAvailable();
  }

  /// Get network interface information
  Future<List<String>> getNetworkInterfaces() async {
    return await _api.getNetworkInterfaces();
  }

  /// Dispose resources
  void dispose() {
    _deviceDiscoveredController.close();
    _deviceRemovedController.close();
    _deviceUpdatedController.close();
    _discoveryErrorController.close();
    _discoveryCompletedController.close();
    _transportStateChangedController.close();
    _positionChangedController.close();
    _volumeChangedController.close();
    _trackChangedController.close();
    _playbackErrorController.close();
    _contentDirectoryUpdatedController.close();
    _contentDirectoryErrorController.close();
  }
}

// Implementation classes for Flutter API callbacks

class _DeviceDiscoveryApiImpl extends DeviceDiscoveryApi {
  final MediaCastDlnaController _controller;

  _DeviceDiscoveryApiImpl(this._controller);

  @override
  void onDeviceDiscovered(DlnaDevice device) {
    _controller._deviceDiscoveredController.add(device);
  }

  @override
  void onDeviceUpdated(DlnaDevice device) {
    _controller._deviceUpdatedController.add(device);
  }

  @override
  void onDiscoveryError(String error) {
    _controller._discoveryErrorController.add(error);
  }

  @override
  void onDiscoveryCompleted() {
    _controller._discoveryCompletedController.add(null);
  }

  @override
  void onDeviceRemoved(DlnaDevice deviceUdn) {
    _controller._deviceRemovedController.add(deviceUdn);
  }
}

class _MediaRendererEventsApiImpl extends MediaRendererEventsApi {
  final MediaCastDlnaController _controller;

  _MediaRendererEventsApiImpl(this._controller);

  @override
  void onTransportStateChanged(String deviceUdn, TransportState state) {
    _controller._transportStateChangedController.add((
      deviceUdn: deviceUdn,
      state: state,
    ));
  }

  @override
  void onPositionChanged(String deviceUdn, int positionSeconds) {
    _controller._positionChangedController.add((
      deviceUdn: deviceUdn,
      positionSeconds: positionSeconds,
    ));
  }

  @override
  void onVolumeChanged(String deviceUdn, VolumeInfo volumeInfo) {
    _controller._volumeChangedController.add((
      deviceUdn: deviceUdn,
      volumeInfo: volumeInfo,
    ));
  }

  @override
  void onTrackChanged(
    String deviceUdn,
    String? trackUri,
    String? trackMetadata,
  ) {
    _controller._trackChangedController.add((
      deviceUdn: deviceUdn,
      trackUri: trackUri,
      trackMetadata: trackMetadata,
    ));
  }

  @override
  void onPlaybackError(String deviceUdn, String error) {
    _controller._playbackErrorController.add((
      deviceUdn: deviceUdn,
      error: error,
    ));
  }
}

class _MediaServerEventsApiImpl extends MediaServerEventsApi {
  final MediaCastDlnaController _controller;

  _MediaServerEventsApiImpl(this._controller);

  @override
  void onContentDirectoryUpdated(String deviceUdn, String containerId) {
    _controller._contentDirectoryUpdatedController.add((
      deviceUdn: deviceUdn,
      containerId: containerId,
    ));
  }

  @override
  void onContentDirectoryError(String deviceUdn, String error) {
    _controller._contentDirectoryErrorController.add((
      deviceUdn: deviceUdn,
      error: error,
    ));
  }
}

import 'package:flutter/foundation.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'dart:async';

/// Global DLNA connection manager that can be shared across all tabs
class DlnaConnectionManager extends ChangeNotifier {
  static final DlnaConnectionManager _instance = DlnaConnectionManager._internal();
  factory DlnaConnectionManager() => _instance;
  DlnaConnectionManager._internal();

  final MediaCastDlnaController _dlnaController = MediaCastDlnaController.instance;
  
  List<DlnaDevice> _discoveredDevices = [];
  String? _selectedRendererUdn;
  DlnaDevice? _selectedDevice;
  bool _isDiscovering = false;
  bool _isInitialized = false;
  PlaybackInfo? _currentPlaybackInfo;
  VolumeInfo? _currentVolumeInfo;

  // Stream subscriptions
  StreamSubscription? _deviceDiscoveredSub;
  StreamSubscription? _deviceRemovedSub;
  StreamSubscription? _transportStateSub;
  StreamSubscription? _volumeChangedSub;

  // Getters
  List<DlnaDevice> get discoveredDevices => _discoveredDevices;
  String? get selectedRendererUdn => _selectedRendererUdn;
  DlnaDevice? get selectedDevice => _selectedDevice;
  bool get isDiscovering => _isDiscovering;
  bool get isInitialized => _isInitialized;
  bool get hasSelectedDevice => _selectedRendererUdn != null;
  PlaybackInfo? get currentPlaybackInfo => _currentPlaybackInfo;
  VolumeInfo? get currentVolumeInfo => _currentVolumeInfo;
  MediaCastDlnaController get controller => _dlnaController;

  /// Initialize the DLNA service and set up event listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _dlnaController.initializeUpnpService();
      _setupEventListeners();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing DLNA service: $e');
      rethrow;
    }
  }

  void _setupEventListeners() {
    _deviceDiscoveredSub = _dlnaController.onDeviceDiscovered.listen((device) {
      // Use extension method to add or update device - prevents duplicates by UDN comparison
      _discoveredDevices.addOrUpdate(device);
      notifyListeners();
    });

    _deviceRemovedSub = _dlnaController.onDeviceRemoved.listen((device) {
      // Use extension method to remove device by UDN
      _discoveredDevices.removeByUdn(device.udn);
      if (_selectedRendererUdn == device.udn) {
        _selectedRendererUdn = null;
        _selectedDevice = null;
        _currentPlaybackInfo = null;
        _currentVolumeInfo = null;
      }
      notifyListeners();
    });

    _transportStateSub = _dlnaController.onTransportStateChanged.listen((event) {
      if (event.deviceUdn == _selectedRendererUdn) {
        updatePlaybackInfo();
      }
    });

    _volumeChangedSub = _dlnaController.onVolumeChanged.listen((event) {
      if (event.deviceUdn == _selectedRendererUdn) {
        updateVolumeInfo();
      }
    });
  }

  /// Start device discovery
  Future<void> startDiscovery({int timeoutSeconds = 10}) async {
    if (!_isInitialized) {
      await initialize();
    }

    _isDiscovering = true;
    _discoveredDevices.clear();
    notifyListeners();

    try {
      await _dlnaController.startDiscovery(timeoutSeconds: timeoutSeconds);
    } catch (e) {
      _isDiscovering = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      await _dlnaController.stopDiscovery();
    } catch (e) {
      print('Error stopping discovery: $e');
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Select a renderer device
  void selectRenderer(String rendererUdn) {
    _selectedRendererUdn = rendererUdn;
    _selectedDevice = _discoveredDevices.findByUdn(rendererUdn);
    _currentPlaybackInfo = null;
    _currentVolumeInfo = null;
    
    notifyListeners();
    
    // Update playback and volume info
    updatePlaybackInfo();
    updateVolumeInfo();
  }

  /// Clear the selected renderer
  void clearSelectedRenderer() {
    _selectedRendererUdn = null;
    _selectedDevice = null;
    _currentPlaybackInfo = null;
    _currentVolumeInfo = null;
    notifyListeners();
  }

  /// Update playback information
  Future<void> updatePlaybackInfo() async {
    if (_selectedRendererUdn == null) return;

    try {
      final playbackInfo = await _dlnaController.getPlaybackInfo(_selectedRendererUdn!);
      _currentPlaybackInfo = playbackInfo;
      notifyListeners();
    } catch (e) {
      // Handle error silently for now
      print('Error updating playback info: $e');
    }
  }

  /// Update volume information
  Future<void> updateVolumeInfo() async {
    if (_selectedRendererUdn == null) return;

    try {
      final volumeInfo = await _dlnaController.getVolumeInfo(_selectedRendererUdn!);
      _currentVolumeInfo = volumeInfo;
      notifyListeners();
    } catch (e) {
      // Handle error silently for now
      print('Error updating volume info: $e');
    }
  }

  /// Play media on the selected device
  Future<void> playMedia(String mediaUrl, {required MediaMetadata metadata}) async {
    if (_selectedRendererUdn == null) {
      throw Exception('No device selected');
    }

    await _dlnaController.playMedia(_selectedRendererUdn!, mediaUrl, metadata: metadata);
    updatePlaybackInfo();
  }

  /// Control playback (play, pause, stop)
  Future<void> controlPlayback(String action) async {
    if (_selectedRendererUdn == null) {
      throw Exception('No device selected');
    }

    switch (action) {
      case 'play':
        await _dlnaController.play(_selectedRendererUdn!);
        break;
      case 'pause':
        await _dlnaController.pause(_selectedRendererUdn!);
        break;
      case 'stop':
        await _dlnaController.stop(_selectedRendererUdn!);
        break;
      default:
        throw Exception('Unknown playback action: $action');
    }
    
    updatePlaybackInfo();
  }

  /// Set volume
  Future<void> setVolume(int volume) async {
    if (_selectedRendererUdn == null) {
      throw Exception('No device selected');
    }

    await _dlnaController.setVolume(_selectedRendererUdn!, volume);
    updateVolumeInfo();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (_selectedRendererUdn == null || _currentVolumeInfo == null) {
      throw Exception('No device selected or volume info unavailable');
    }

    await _dlnaController.setMute(_selectedRendererUdn!, !_currentVolumeInfo!.muted);
    updateVolumeInfo();
  }

  @override
  void dispose() {
    _deviceDiscoveredSub?.cancel();
    _deviceRemovedSub?.cancel();
    _transportStateSub?.cancel();
    _volumeChangedSub?.cancel();
    super.dispose();
  }
}

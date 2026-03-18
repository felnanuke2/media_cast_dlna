import 'package:flutter/material.dart';
import 'dart:async';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'cast_devices_modal.dart';
import 'core/constants/app_constants.dart';
import 'core/models/app_models.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/media_utils.dart';
import 'core/utils/ui_utils.dart';
import 'presentation/widgets/device_selection_widget.dart';
import 'presentation/widgets/playback_control_widget.dart';
import 'presentation/widgets/test_media_widget.dart';
import 'services/media_cast_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      home: const DlnaHomePage(),
    );
  }
}

class DlnaHomePage extends StatefulWidget {
  const DlnaHomePage({super.key});

  @override
  State<DlnaHomePage> createState() => _DlnaHomePageState();
}

class _DlnaHomePageState extends State<DlnaHomePage> {
  static const List<double> _defaultSpeedOptions = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  late final MediaCastService _mediaService;
  late final MediaCastDlnaDiscoveryEvents _discoveryEvents;
  final TextEditingController _customUrlController = TextEditingController();
  StreamSubscription<DlnaDevice>? _onDeviceFoundSubscription;
  StreamSubscription<DeviceUdn>? _onRendererOfflineSubscription;

  // State variables
  DlnaDevice? _selectedDevice;
  PlaybackState _playbackState = const PlaybackState();
  DeviceConnectivityState _connectivityState = const DeviceConnectivityState();
  List<double> _supportedSpeedOptions = _defaultSpeedOptions;

  @override
  void initState() {
    super.initState();
    _mediaService = MediaCastService();
    _discoveryEvents = MediaCastDlnaDiscoveryEvents();
    _onDeviceFoundSubscription = _discoveryEvents.onDeviceFound.listen(
      _handleDeviceFound,
    );
    _onRendererOfflineSubscription = _discoveryEvents.onRendererOffline.listen(
      _handleRendererOffline,
    );
    _initializeService();
  }

  @override
  void dispose() {
    _onDeviceFoundSubscription?.cancel();
    _onRendererOfflineSubscription?.cancel();
    _discoveryEvents.dispose();
    _mediaService.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  /// Initializes the media cast service
  Future<void> _initializeService() async {
    try {
      await _mediaService.initialize();
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(
          context,
          '${AppConstants.initializationError}: $e',
        );
      }
    }
  }

  /// Handles device selection
  void _onDeviceSelected(DlnaDevice device) {
    setState(() {
      _selectedDevice = device;
      _connectivityState = const DeviceConnectivityState(isOnline: true);
      _supportedSpeedOptions = _defaultSpeedOptions;
    });

    _startMonitoring(device.udn);
    _loadSupportedPlaybackSpeeds(device.udn);
  }

  Future<void> _loadSupportedPlaybackSpeeds(DeviceUdn deviceUdn) async {
    try {
      final tokens = await _mediaService.getSupportedPlaybackSpeeds(
        deviceUdn: deviceUdn,
      );
      final speeds = tokens.values
          .map((token) => double.tryParse(token.value.trim()))
          .whereType<double>()
          .toList()
        ..sort();

      if (!mounted || _selectedDevice?.udn.value != deviceUdn.value) {
        return;
      }

      if (speeds.isNotEmpty) {
        final currentSpeed = speeds.contains(_playbackState.playbackSpeed)
            ? _playbackState.playbackSpeed
            : speeds.first;
        setState(() {
          _supportedSpeedOptions = speeds;
          _playbackState = _playbackState.copyWith(playbackSpeed: currentSpeed);
        });
      }
    } catch (_) {
      // Keep defaults when capability probing fails.
    }
  }

  /// Starts monitoring for the selected device
  void _startMonitoring(DeviceUdn deviceUdn) {
    _mediaService.startPlaybackInfoMonitoring(
      deviceUdn: deviceUdn,
      onUpdate: () {},
      onPlaybackStateChanged: (state) {
        if (mounted) {
          setState(() {
            _playbackState = state;
          });
        }
      },
      onConnectivityChanged: _handleConnectivityChanged,
    );
  }

  void _handleDeviceFound(DlnaDevice device) {
    final selectedUdn = _selectedDevice?.udn.value;
    if (!mounted || selectedUdn == null || selectedUdn != device.udn.value) {
      return;
    }

    _handleConnectivityChanged(
      DeviceConnectivityState(
        isOnline: true,
        lastConnectivityCheck: DateTime.now(),
      ),
    );
  }

  void _handleRendererOffline(DeviceUdn deviceUdn) {
    final selectedUdn = _selectedDevice?.udn.value;
    if (!mounted || selectedUdn == null || selectedUdn != deviceUdn.value) {
      return;
    }

    _handleConnectivityChanged(
      DeviceConnectivityState(
        isOnline: false,
        lastConnectivityCheck: DateTime.now(),
      ),
    );
  }

  /// Handles connectivity state changes
  void _handleConnectivityChanged(DeviceConnectivityState newState) {
    if (mounted) {
      final wasOnline = _connectivityState.isOnline;
      setState(() {
        _connectivityState = newState;
      });

      // Show notifications for connectivity changes
      if (wasOnline && !newState.isOnline) {
        UiUtils.showErrorSnackBar(
          context,
          'Device "${_selectedDevice?.friendlyName}" is offline',
        );
      } else if (!wasOnline && newState.isOnline) {
        UiUtils.showSuccessSnackBar(
          context,
          'Device "${_selectedDevice?.friendlyName}" is back online',
        );
      }
    }
  }

  /// Handles playback control actions
  Future<void> _onPlaybackControl(String action) async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.controlPlayback(
        deviceUdn: _selectedDevice!.udn,
        action: action,
      );
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.playbackError}: $e');
      }
    }
  }

  /// Handles volume changes
  Future<void> _onVolumeChange(int volume) async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.setVolume(
        deviceUdn: _selectedDevice!.udn,
        volume: volume,
      );
      setState(() {
        _playbackState = _playbackState.copyWith(currentVolume: volume);
      });
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.volumeError}: $e');
      }
    }
  }

  /// Handles seek operations
  Future<void> _onSeek(int positionSeconds) async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.seekTo(
        deviceUdn: _selectedDevice!.udn,
        positionSeconds: positionSeconds,
      );
      setState(() {
        _playbackState = _playbackState.copyWith(
          currentPosition: positionSeconds,
        );
      });
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.seekError}: $e');
      }
    }
  }

  /// Handles mute toggle
  Future<void> _onToggleMute() async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.toggleMute(
        deviceUdn: _selectedDevice!.udn,
        currentMuteState: _playbackState.isMuted,
      );
      setState(() {
        _playbackState = _playbackState.copyWith(
          isMuted: !_playbackState.isMuted,
        );
      });
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.muteError}: $e');
      }
    }
  }

  /// Handles slider drag state changes
  void _onSliderDragChanged(bool isDragging) {
    setState(() {
      _playbackState = _playbackState.copyWith(
        isSliderBeingDragged: isDragging,
      );
    });
  }

  /// Handles test media playback
  Future<void> _onPlayTestMedia(TestMediaItem media) async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.playMedia(
        deviceUdn: _selectedDevice!.udn,
        mediaUrl: media.url,
        metadata: media.toMediaMetadata(),
      );
      if (mounted) {
        UiUtils.showSuccessSnackBar(context, 'Playing: ${media.title}');
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.playbackError}: $e');
      }
    }
  }

  /// Handles custom URL playback
  Future<void> _onPlayCustomUrl(String url) async {
    if (_selectedDevice?.udn == null || url.isEmpty) return;

    try {
      final metadata = MediaUtils.createCustomMediaMetadata(
        title: 'Custom Media',
        url: url,
      );

      await _mediaService.playMedia(
        deviceUdn: _selectedDevice!.udn,
        mediaUrl: url,
        metadata: metadata,
      );
      if (mounted) {
        UiUtils.showSuccessSnackBar(context, 'Playing custom media');
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, '${AppConstants.playbackError}: $e');
      }
    }
  }

  /// Shows the cast devices modal
  void _showCastDevicesModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return CastDevicesModal(
          selectedRendererUdn: _selectedDevice?.udn,
          onSelectRenderer: _onDeviceSelected,
        );
      },
    );
  }

  /// Handles playback speed changes
  Future<void> _onSpeedChange(double speed) async {
    if (_selectedDevice?.udn == null) return;

    try {
      await _mediaService.setPlaybackSpeed(
        deviceUdn: _selectedDevice!.udn,
        speed: speed,
      );
      setState(() {
        _playbackState = _playbackState.copyWith(playbackSpeed: speed);
      });
      if (mounted) {
        UiUtils.showSuccessSnackBar(context, 'Playback speed set to ${speed}x');
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showErrorSnackBar(context, 'Failed to set playback speed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _selectedDevice != null ? Icons.cast_connected : Icons.cast,
            ),
            onPressed: () {
              if (_selectedDevice != null) {
                // Stop monitoring timers and reset selected renderer
                _mediaService.stopMonitoring();
                setState(() {
                  _selectedDevice = null;
                  _supportedSpeedOptions = _defaultSpeedOptions;
                });
              } else {
                _showCastDevicesModal();
              }
            },
            tooltip: _selectedDevice != null
                ? 'Disconnect from device'
                : 'Cast to device',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DeviceSelectionWidget(
              selectedDevice: _selectedDevice,
              isOnline: _connectivityState.isOnline,
              lastConnectivityCheck: _connectivityState.lastConnectivityCheck,
              onCastPressed: _showCastDevicesModal,
            ),
          ),
          if (_selectedDevice?.udn != null) ...[
            const SliverToBoxAdapter(child: Divider()),
            SliverToBoxAdapter(
              child: PlaybackControlWidget(
                playbackState: _playbackState,
                isDeviceOnline: _connectivityState.isOnline,
                onPlaybackControl: _onPlaybackControl,
                onVolumeChange: _onVolumeChange,
                onSeek: _onSeek,
                onToggleMute: _onToggleMute,
                onSliderDragChanged: _onSliderDragChanged,
                onSpeedChange: _onSpeedChange,
                speedOptions: _supportedSpeedOptions,
              ),
            ),
            SliverToBoxAdapter(
              child: TestMediaWidget(
                isDeviceOnline: _connectivityState.isOnline,
                onPlayMedia: _onPlayTestMedia,
                onPlayCustomUrl: _onPlayCustomUrl,
                customUrlController: _customUrlController,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

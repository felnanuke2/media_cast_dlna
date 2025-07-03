import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../core/utils/ui_utils.dart';

/// Widget for controlling media playback
class PlaybackControlWidget extends StatelessWidget {
  final PlaybackState playbackState;
  final bool isDeviceOnline;
  final Function(String) onPlaybackControl;
  final Function(int) onVolumeChange;
  final Function(int) onSeek;
  final VoidCallback onToggleMute;
  final Function(bool) onSliderDragChanged;

  const PlaybackControlWidget({
    super.key,
    required this.playbackState,
    required this.isDeviceOnline,
    required this.onPlaybackControl,
    required this.onVolumeChange,
    required this.onSeek,
    required this.onToggleMute,
    required this.onSliderDragChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppConstants.defaultPadding),
            if (!isDeviceOnline) _buildOfflineWarning(context),
            _buildMediaInfo(context),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildSeekSlider(context),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildPlaybackButtons(context),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildVolumeControl(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'Playback Controls',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (!isDeviceOnline) _buildOfflineIndicator(),
      ],
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.offlineColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            'Device Offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              AppConstants.deviceOfflineMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaInfo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumbnail(),
        const SizedBox(width: AppConstants.defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (playbackState.currentTrackTitle.isNotEmpty) ...[
                Text(
                  playbackState.currentTrackTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: AppConstants.smallPadding),
              ],
              _buildTransportStateIndicator(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: AppConstants.thumbnailSize,
      height: AppConstants.thumbnailSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Colors.grey[300],
      ),
      child: playbackState.currentThumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Image.network(
                playbackState.currentThumbnailUrl!,
                width: AppConstants.thumbnailSize,
                height: AppConstants.thumbnailSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingThumbnail();
                },
              ),
            )
          : _buildDefaultThumbnail(),
    );
  }

  Widget _buildDefaultThumbnail() {
    return const Icon(
      Icons.music_note,
      size: 40,
      color: Colors.grey,
    );
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      width: AppConstants.thumbnailSize,
      height: AppConstants.thumbnailSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        color: Colors.grey[300],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildTransportStateIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          UiUtils.getTransportStateIcon(playbackState.transportState),
          color: UiUtils.getTransportStateColor(playbackState.transportState),
          size: 20,
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Text(
          UiUtils.getTransportStateText(playbackState.transportState),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: UiUtils.getTransportStateColor(playbackState.transportState),
          ),
        ),
      ],
    );
  }

  Widget _buildSeekSlider(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: playbackState.isSliderBeingDragged
              ? playbackState.currentPosition.toDouble()
              : (playbackState.duration > 0
                  ? playbackState.currentPosition.toDouble()
                  : 0),
          min: 0,
          max: playbackState.duration > 0 ? playbackState.duration.toDouble() : 100,
          onChanged: isDeviceOnline
              ? (value) {
                  onSliderDragChanged(true);
                  onSeek(value.round());
                }
              : null,
          onChangeEnd: isDeviceOnline
              ? (value) {
                  onSeek(value.round());
                  onSliderDragChanged(false);
                }
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              FormatUtils.formatDuration(playbackState.currentPosition),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              FormatUtils.formatDuration(playbackState.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.play_arrow,
            size: AppConstants.playButtonSize,
            color: AppTheme.playingColor,
          ),
          onPressed: isDeviceOnline ? () => onPlaybackControl('play') : null,
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        IconButton(
          icon: const Icon(
            Icons.pause,
            size: AppConstants.playButtonSize,
            color: AppTheme.pausedColor,
          ),
          onPressed: isDeviceOnline ? () => onPlaybackControl('pause') : null,
        ),
        const SizedBox(width: AppConstants.defaultPadding),
        IconButton(
          icon: const Icon(
            Icons.stop,
            size: AppConstants.stopButtonSize,
            color: AppTheme.stoppedColor,
          ),
          onPressed: isDeviceOnline ? () => onPlaybackControl('stop') : null,
        ),
      ],
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            playbackState.isMuted ? Icons.volume_off : Icons.volume_up,
          ),
          onPressed: isDeviceOnline ? onToggleMute : null,
        ),
        Expanded(
          child: Slider(
            value: playbackState.currentVolume.toDouble(),
            min: 0,
            max: AppConstants.maxVolume.toDouble(),
            divisions: AppConstants.volumeDivisions,
            onChanged: isDeviceOnline
                ? (value) => onVolumeChange(value.round())
                : null,
          ),
        ),
        Text(
          '${playbackState.currentVolume}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

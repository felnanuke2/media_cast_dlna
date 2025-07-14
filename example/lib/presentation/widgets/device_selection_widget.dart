import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';

/// Widget displaying device selection status
class DeviceSelectionWidget extends StatelessWidget {
  final DlnaDevice? selectedDevice;
  final bool isOnline;
  final DateTime? lastConnectivityCheck;
  final VoidCallback onCastPressed;

  const DeviceSelectionWidget({
    super.key,
    required this.selectedDevice,
    required this.isOnline,
    required this.lastConnectivityCheck,
    required this.onCastPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedDevice != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                Text(
                  'Selected renderer: ${selectedDevice?.friendlyName ?? "Unknown"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                _buildConnectionStatus(),
              ],
            ),
            if (lastConnectivityCheck != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last checked: ${FormatUtils.formatTime(lastConnectivityCheck!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ] else ...[
            const SizedBox(height: AppConstants.defaultPadding),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.cast,
                    size: AppConstants.iconSize,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Tap the cast button to find a device',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isOnline ? AppTheme.onlineColor : AppTheme.offlineColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

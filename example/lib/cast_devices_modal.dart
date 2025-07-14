import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';

class CastDevicesModal extends StatefulWidget {
  final DeviceUdn? selectedRendererUdn;
  final Function(DlnaDevice) onSelectRenderer;

  const CastDevicesModal({
    super.key,
    required this.selectedRendererUdn,
    required this.onSelectRenderer,
  });

  @override
  State<CastDevicesModal> createState() => _CastDevicesModalState();
}

class _CastDevicesModalState extends State<CastDevicesModal> {
  List<DlnaDevice> _localDiscoveredDevices = [];
  DeviceUdn? _localSelectedRendererUdn;
  Timer? _discoveryTimer;
  final _api = MediaCastDlnaApi();

  @override
  void initState() {
    super.initState();
    _localSelectedRendererUdn = widget.selectedRendererUdn;
    _api.startDiscovery(
      DiscoveryOptions(timeout: DiscoveryTimeout(seconds: 10)),
    );
    _getDevices();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 5), _getDevices);
  }

  @override
  void dispose() {
    _api.stopDiscovery();
    _discoveryTimer?.cancel();
    _localSelectedRendererUdn = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(CastDevicesModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mounted) {
      setState(() {
        _localSelectedRendererUdn = widget.selectedRendererUdn;
      });
    }
  }

  void _showDeviceDetails(BuildContext context, DlnaDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Device Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', device.friendlyName),
                _buildDetailRow('UDN', device.udn.value),
                _buildDetailRow('Type', device.deviceType),
                _buildDetailRow(
                  'Manufacturer',
                  device.manufacturerDetails.manufacturer,
                ),
                _buildDetailRow('Model', device.modelDetails.modelName),
                _buildDetailRow('IP Address', device.ipAddress.value),
                _buildDetailRow('Port', device.port.value.toString()),
                _buildDetailRow(
                  'Description',
                  device.modelDetails.modelDescription ?? 'No description',
                ),
                if (device.presentationUrl != null)
                  _buildDetailRow(
                    'Presentation URL',
                    device.presentationUrl!.value,
                  ),
                if (device.icons != null && device.icons!.isNotEmpty)
                  ...device.icons!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final icon = entry.value;
                    return _buildDetailRow(
                      'Icon ${index + 1}',
                      '${icon.uri.value} (${icon.width}x${icon.height}, ${icon.mimeType})',
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon(DlnaDevice device, bool isSelected) {
    // Try to get the first available icon, preferring smaller sizes for list display
    DeviceIcon? bestIcon;

    if (device.icons != null && device.icons!.isNotEmpty) {
      // Sort icons by size (width * height) and pick the smallest suitable one
      final sortedIcons = List<DeviceIcon>.from(device.icons!)
        ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));

      // Prefer icons that are reasonably sized for list display (32x32 to 64x64)
      bestIcon = sortedIcons.firstWhere(
        (icon) => icon.width >= 32 && icon.width <= 64,
        orElse: () => sortedIcons.first,
      );
    }

    const double iconSize = 40.0;

    if (bestIcon != null) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            bestIcon.uri.value,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default icon if image fails to load
              return Icon(
                isSelected ? Icons.cast_connected : Icons.cast,
                color: isSelected ? Colors.blue : Colors.grey,
                size: iconSize * 0.6,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Fallback to default cast icon if no device icon is available
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Icon(
          isSelected ? Icons.cast_connected : Icons.cast,
          color: isSelected ? Colors.blue : Colors.grey,
          size: iconSize * 0.6,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cast to device',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_localDiscoveredDevices.isEmpty && _discoveryTimer != null) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Searching for devices...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_localDiscoveredDevices.isEmpty) ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.cast_connected, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No devices found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Make sure your devices are on the same network',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _localDiscoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _localDiscoveredDevices[index];
                  final isRenderer = device.deviceType.contains(
                    'MediaRenderer',
                  );
                  final isSelected =
                      device.udn.value == _localSelectedRendererUdn?.value;

                  if (!isRenderer) return const SizedBox.shrink();

                  return ListTile(
                    leading: _buildDeviceIcon(device, isSelected),
                    title: Text(
                      device.friendlyName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${device.manufacturerDetails.manufacturer} • ${device.ipAddress.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.blue),
                        IconButton(
                          onPressed: () => _showDeviceDetails(context, device),
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Device Details',
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isSelected) {
                        setState(() {
                          _localSelectedRendererUdn = device.udn;
                        });
                        widget.onSelectRenderer(device);
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _getDevices([Timer? timer]) {
    _api
        .getDiscoveredDevices()
        .then((devices) {
          if (mounted) {
            setState(() {
              _localDiscoveredDevices = devices;
            });
          }
        })
        .catchError((error) {
          // Handle any errors that occur during discovery
          debugPrint('Error during device discovery: $error');
        });
  }
}

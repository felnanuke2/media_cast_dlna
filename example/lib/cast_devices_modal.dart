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
    _api.startDiscovery(DiscoveryOptions(timeout: DiscoveryTimeout(seconds: 10)));
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
                _buildDetailRow('Manufacturer', device.manufacturerName),
                _buildDetailRow('Model', device.modelName),
                _buildDetailRow('IP Address', device.ipAddress.value),
                _buildDetailRow('Port', device.port.value.toString()),
                _buildDetailRow(
                  'Description',
                  device.modelDescription ?? 'No description',
                ),
                if (device.presentationUrl != null)
                  _buildDetailRow('Presentation URL', device.presentationUrl!.value),
                if (device.iconUrl != null)
                  _buildDetailRow('Icon URL', device.iconUrl!.value),
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
                    leading: Icon(
                      isSelected ? Icons.cast_connected : Icons.cast,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      device.friendlyName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${device.manufacturerName} • ${device.ipAddress}',
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
          print('Error during device discovery: $error');
        });
  }
}

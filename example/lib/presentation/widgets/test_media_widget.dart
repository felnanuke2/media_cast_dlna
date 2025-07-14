import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/ui_utils.dart';
import '../../data/repositories/test_media_repository.dart';

/// Widget for displaying and controlling test media
class TestMediaWidget extends StatelessWidget {
  final bool isDeviceOnline;
  final Function(TestMediaItem) onPlayMedia;
  final Function(String) onPlayCustomUrl;
  final TextEditingController customUrlController;

  const TestMediaWidget({
    super.key,
    required this.isDeviceOnline,
    required this.onPlayMedia,
    required this.onPlayCustomUrl,
    required this.customUrlController,
  });

  @override
  Widget build(BuildContext context) {
    final testMediaItems = TestMediaRepository.getTestMediaItems();

    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Media',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ...testMediaItems.map((media) => _buildMediaItem(context, media)),
            const SizedBox(height: AppConstants.defaultPadding),
            _buildCustomUrlSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(BuildContext context, TestMediaItem media) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          UiUtils.getMediaIcon(media.type),
          color: UiUtils.getMediaColor(media.type),
        ),
        title: Text(
          media.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          media.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: ElevatedButton(
          onPressed: isDeviceOnline ? () => onPlayMedia(media) : null,
          child: const Text('Play'),
        ),
      ),
    );
  }

  Widget _buildCustomUrlSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Play Custom URL',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: customUrlController,
                decoration: const InputDecoration(
                  labelText: 'Enter media URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/media.mp4',
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            ElevatedButton(
              onPressed: isDeviceOnline
                  ? () => onPlayCustomUrl(customUrlController.text.trim())
                  : null,
              child: const Text('Play'),
            ),
          ],
        ),
      ],
    );
  }
}

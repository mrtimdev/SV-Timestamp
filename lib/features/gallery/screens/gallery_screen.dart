import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/photo_storage_service.dart';
import '../../../models/captured_photo.dart';
import '../../../core/utils/app_strings.dart';
import '../../settings/providers/settings_provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final storage = PhotoStorageService();
  String query = '';
  late Future<List<CapturedPhoto>> photos = storage.list();
  void refresh() => setState(() => photos = storage.list());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(
      context.watch<SettingsProvider>().settings.language,
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('Gallery', 'វិចិត្រសាល'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              strings.text(
                'Your timestamped captures',
                'រូបថតមានត្រាពេលវេលារបស់អ្នក',
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: strings.text(
                  'Search by capture date',
                  'ស្វែងរកតាមកាលបរិច្ឆេទ',
                ),
                suffixIcon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CapturedPhoto>>(
              future: photos,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visible = snapshot.data!
                    .where(
                      (photo) => DateFormat('MMM d, yyyy')
                          .format(photo.capturedAt)
                          .toLowerCase()
                          .contains(query.toLowerCase()),
                    )
                    .toList();
                if (visible.isEmpty) return _EmptyGallery(strings: strings);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .76,
                  ),
                  itemBuilder: (context, index) =>
                      _PhotoTile(photo: visible[index], onChanged: refresh),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onChanged});
  final CapturedPhoto photo;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () => showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(File(photo.path)),
        ),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: photo.path,
            child: Image.file(File(photo.path), fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Text(
              DateFormat('MMM d\nhh:mm a').format(photo.capturedAt),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: (value) async {
                if (value == 'share') {
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(photo.path)]),
                  );
                }
                if (value == 'delete') {
                  await PhotoStorageService().delete(photo.path);
                  onChanged();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Share')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.strings});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 14),
        Text(
          strings.text('No captures yet', 'មិនទាន់មានរូបថត'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          strings.text(
            'Your timestamped photos will appear here.',
            'រូបថតមានត្រាពេលវេលានឹងបង្ហាញនៅទីនេះ។',
          ),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}

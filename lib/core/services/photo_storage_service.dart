import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/captured_photo.dart';

class PhotoStorageService {
  Future<Directory> _directory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(docs.path, 'sv_timestamp_photos'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> newPath() async {
    final dir = await _directory();
    return path.join(
      dir.path,
      'SV_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<List<CapturedPhoto>> list() async {
    final dir = await _directory();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.jpg'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    return files
        .map(
          (file) => CapturedPhoto(
            path: file.path,
            capturedAt: file.lastModifiedSync(),
          ),
        )
        .toList();
  }

  Future<void> delete(String photoPath) async {
    final file = File(photoPath);
    if (file.existsSync()) await file.delete();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:sv_timestamp/models/app_settings.dart';
import 'package:sv_timestamp/core/services/photo_storage_service.dart';
import 'package:sv_timestamp/features/gallery/screens/gallery_screen.dart';
import 'package:sv_timestamp/features/settings/providers/settings_provider.dart';
import 'package:sv_timestamp/models/captured_photo.dart';

class _Storage extends PhotoStorageService {
  _Storage(this.photos);
  final List<CapturedPhoto> photos;
  final deleted = <String>[];
  Completer<void>? pendingDelete;
  bool failDelete = false;

  @override
  Future<List<CapturedPhoto>> list() async => List.of(photos);

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
    await pendingDelete?.future;
    if (failDelete) throw const FileSystemException('Delete failed');
    photos.removeWhere((photo) => photo.path == path);
  }
}

void main() {
  late Directory directory;
  late _Storage storage;
  late SettingsProvider settings;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('gallery_delete_test');
    final png = img.encodePng(img.Image(width: 2, height: 2));
    storage = _Storage(
      List.generate(2, (index) {
        final file = File('${directory.path}/$index.png')
          ..writeAsBytesSync(png);
        return CapturedPhoto(
          path: file.path,
          capturedAt: DateTime(2026, 9, 28 - index),
        );
      }),
    );
    settings = SettingsProvider()
      ..settings = const AppSettings(language: AppLanguage.english);
  });

  tearDown(() {
    settings.dispose();
    directory.deleteSync(recursive: true);
  });

  Future<void> openGallery(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(home: GalleryScreen(storage: storage)),
      ),
    );
    await tester.runAsync(() async {
      for (final photo in storage.photos) {
        await precacheImage(
          FileImage(File(photo.path)),
          tester.element(find.byType(GalleryScreen)),
        );
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> quickDelete(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
  }

  testWidgets('quick delete updates count and removes only the deleted card', (
    tester,
  ) async {
    await openGallery(tester);
    final removed = storage.photos.first.path;
    final retained = storage.photos.last.path;
    expect(find.text('2 captures'), findsOneWidget);
    storage.pendingDelete = Completer<void>();
    await quickDelete(tester);
    expect(find.text('2 captures'), findsOneWidget);
    storage.pendingDelete!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(removed)), findsNothing);
    expect(find.byKey(ValueKey(retained)), findsOneWidget);
    expect(find.text('1 captures'), findsOneWidget);
    await quickDelete(tester);
    expect(find.byType(GridView), findsNothing);
    expect(storage.deleted, [removed, retained]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer deletes the swiped photo and refreshes the gallery', (
    tester,
  ) async {
    await openGallery(tester);
    final first = storage.photos.first.path;
    final second = storage.photos.last.path;
    await tester.tap(
      find
          .descendant(
            of: find.byKey(ValueKey(first)),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.deleted, isEmpty);
    await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(storage.deleted, [second]);
    expect(find.byType(PageView), findsNothing);
    expect(find.byKey(ValueKey(first)), findsOneWidget);
    expect(find.byKey(ValueKey(second)), findsNothing);
    expect(find.text('1 captures'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion with a date filter does not hide remaining photos', (
    tester,
  ) async {
    await openGallery(tester);
    await tester.enterText(find.byType(TextField), 'Sep 28');
    await tester.pumpAndSettle();
    expect(find.text('1 captures'), findsOneWidget);
    await quickDelete(tester);
    expect(find.byType(GridView), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('1 captures'), findsOneWidget);
    expect(find.byKey(ValueKey(storage.photos.single.path)), findsOneWidget);
  });

  testWidgets('leaving the viewer during deletion does not pop the gallery', (
    tester,
  ) async {
    await openGallery(tester);
    final path = storage.photos.first.path;
    await tester.tap(
      find
          .descendant(
            of: find.byKey(ValueKey(path)),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.pumpAndSettle();
    storage.pendingDelete = Completer<void>();
    await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    storage.pendingDelete!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GalleryScreen), findsOneWidget);
    expect(find.text('1 captures'), findsOneWidget);
    expect(find.byKey(ValueKey(path)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed delete retains the photo and allows retry', (
    tester,
  ) async {
    storage.failDelete = true;
    await openGallery(tester);
    final path = storage.photos.first.path;
    await quickDelete(tester);
    expect(find.byKey(ValueKey(path)), findsOneWidget);
    expect(find.text('2 captures'), findsOneWidget);
    expect(
      find.text('Could not delete photo. Please try again.'),
      findsOneWidget,
    );
    storage.failDelete = false;
    await quickDelete(tester);
    expect(find.byKey(ValueKey(path)), findsNothing);
    expect(find.text('1 captures'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

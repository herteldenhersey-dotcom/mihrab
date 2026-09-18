import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mihrab/data/datasources/local/hive_adapters.dart';
import 'package:mihrab/data/datasources/local/hive_boxes.dart';
import 'package:mihrab/data/datasources/local/hive_feedback_local.dart';
import 'package:mihrab/data/repositories/local_feedback_repository.dart';
import 'package:mihrab/domain/enums/feedback_category.dart';
import 'package:mihrab/domain/enums/feedback_delivery_status.dart';
import 'package:mihrab/domain/models/feedback_model.dart';

/// Verifies the delivery-status lifecycle that replaced the old `submitted`
/// boolean. Uses a real Hive box on a temp directory so the adapter's
/// read/write path (including legacy compatibility) is exercised end-to-end.
void main() {
  late Directory tempDir;
  late HiveFeedbackLocal local;

  FeedbackItem makeItem(String id) => FeedbackItem(
        id: id,
        category: FeedbackCategory.bug,
        message: 'Test message $id',
        createdAt: DateTime(2026, 1, 1, 12),
        appVersion: '1.0.0',
      );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mihrab_feedback_test');
    Hive.init(tempDir.path);
    registerHiveAdapters();
    await Hive.openBox<FeedbackItem>(HiveBoxes.feedback);
    local = HiveFeedbackLocal();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.feedback);
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalFeedbackRepository.submit', () {
    test('successful mailto handoff → handoffInitiated', () async {
      final repo = LocalFeedbackRepository(
        local,
        feedbackEmail: 'test@example.com',
        launcher: (uri) async => true, // mail client opened
      );

      final result = await repo.submit(makeItem('a'));

      expect(result.deliveryStatus, FeedbackDeliveryStatus.handoffInitiated);
      // Persisted status matches the returned one.
      final stored = local.getAll().single;
      expect(stored.deliveryStatus, FeedbackDeliveryStatus.handoffInitiated);
    });

    test('launcher returning false → failed (stays queued)', () async {
      final repo = LocalFeedbackRepository(
        local,
        launcher: (uri) async => false, // no mail client handled the intent
      );

      final result = await repo.submit(makeItem('b'));

      expect(result.deliveryStatus, FeedbackDeliveryStatus.failed);
      expect(local.getQueued().map((e) => e.id), contains('b'));
    });

    test('launcher throwing → failed (persisted, not lost)', () async {
      final repo = LocalFeedbackRepository(
        local,
        launcher: (uri) async => throw Exception('no launcher'),
      );

      final result = await repo.submit(makeItem('c'));

      expect(result.deliveryStatus, FeedbackDeliveryStatus.failed);
      // Even on handoff failure the item is persisted.
      expect(local.getAll().single.id, 'c');
    });

    test('mailto URI targets the configured feedback email', () async {
      Uri? captured;
      final repo = LocalFeedbackRepository(
        local,
        feedbackEmail: 'inbox@mihrab.app',
        launcher: (uri) async {
          captured = uri;
          return true;
        },
      );

      await repo.submit(makeItem('d'));

      expect(captured, isNotNull);
      expect(captured!.scheme, 'mailto');
      expect(captured!.path, 'inbox@mihrab.app');
      expect(captured!.query, contains('subject='));
    });
  });

  group('LocalFeedbackRepository.flushQueue', () {
    test('advances only queued items on successful handoff', () async {
      // One already handed-off item, one still pending.
      await local.save(makeItem('kept').copyWith(
          deliveryStatus: FeedbackDeliveryStatus.handoffInitiated));
      await local.save(makeItem('queued')
          .copyWith(deliveryStatus: FeedbackDeliveryStatus.pending));

      expect(local.getQueued().map((e) => e.id), ['queued']);

      final repo = LocalFeedbackRepository(local, launcher: (uri) async => true);
      await repo.flushQueue();

      // The pending item is now handed off; nothing remains queued.
      expect(local.getQueued(), isEmpty);
      final queued = local.getAll().firstWhere((e) => e.id == 'queued');
      expect(queued.deliveryStatus, FeedbackDeliveryStatus.handoffInitiated);
    });

    test('leaves items queued when handoff keeps failing', () async {
      await local.save(makeItem('stuck')
          .copyWith(deliveryStatus: FeedbackDeliveryStatus.pending));

      final repo =
          LocalFeedbackRepository(local, launcher: (uri) async => false);
      await repo.flushQueue();

      expect(local.getQueued().map((e) => e.id), contains('stuck'));
    });
  });

  group('legacy JSON compatibility', () {
    test('legacy submitted=true reads as handoffInitiated', () {
      final item = FeedbackItem.fromJson({
        'id': 'legacy1',
        'category': 'bug',
        'message': 'old',
        'createdAt': DateTime(2025).toIso8601String(),
        'submitted': true,
      });
      expect(item.deliveryStatus, FeedbackDeliveryStatus.handoffInitiated);
    });

    test('legacy submitted=false reads as pending', () {
      final item = FeedbackItem.fromJson({
        'id': 'legacy2',
        'category': 'bug',
        'message': 'old',
        'createdAt': DateTime(2025).toIso8601String(),
        'submitted': false,
      });
      expect(item.deliveryStatus, FeedbackDeliveryStatus.pending);
    });
  });
}

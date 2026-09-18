import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/enums/feedback_category.dart';
import '../../domain/enums/feedback_delivery_status.dart';
import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/local/hive_feedback_local.dart';

/// V1 [FeedbackRepository]: persists to Hive and hands off via a `mailto:`
/// intent (zero backend cost).
///
/// The abstraction is preserved so a Firebase/REST backend can replace this
/// with NO UI changes (see [FirebaseFeedbackRepository] / [RestFeedbackRepository]).
class LocalFeedbackRepository implements FeedbackRepository {
  final HiveFeedbackLocal _local;

  /// Destination email; falls back to [AppConstants.fallbackFeedbackEmail].
  final String feedbackEmail;

  /// Injected for testability (defaults to url_launcher's [launchUrl]).
  final Future<bool> Function(Uri uri) launcher;

  LocalFeedbackRepository(
    this._local, {
    String? feedbackEmail,
    Future<bool> Function(Uri uri)? launcher,
  })  : feedbackEmail = feedbackEmail?.trim().isNotEmpty == true
            ? feedbackEmail!
            : AppConstants.fallbackFeedbackEmail,
        launcher = launcher ?? _defaultLauncher;

  static Future<bool> _defaultLauncher(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<FeedbackItem> submit(FeedbackItem item) async {
    // Persist first so nothing is lost even if the handoff fails.
    final pending = item.deliveryStatus == FeedbackDeliveryStatus.pending
        ? item
        : item.copyWith(deliveryStatus: FeedbackDeliveryStatus.pending);
    try {
      await _local.save(pending);
    } catch (e) {
      throw mapExceptionToFailure(CacheException('Feedback kaydedilemedi',
          cause: e));
    }

    // Attempt the mailto handoff. IMPORTANT: launching the mail client only
    // proves the intent opened — NOT that the mail was actually sent. So the
    // best we can honestly record in V1 is `handoffInitiated`.
    var status = FeedbackDeliveryStatus.failed;
    try {
      final launched = await launcher(_buildMailto(pending));
      status = launched
          ? FeedbackDeliveryStatus.handoffInitiated
          : FeedbackDeliveryStatus.failed;
    } catch (_) {
      // Delivery failed; item stays queued for a later flush. Not fatal.
      status = FeedbackDeliveryStatus.failed;
    }

    await _local.updateStatus(pending.id, status);
    return pending.copyWith(deliveryStatus: status);
  }

  @override
  Future<List<FeedbackItem>> getAll() async => _local.getAll();

  @override
  Future<void> flushQueue() async {
    for (final item in _local.getQueued()) {
      try {
        final ok = await launcher(_buildMailto(item));
        if (ok) {
          await _local.updateStatus(
              item.id, FeedbackDeliveryStatus.handoffInitiated);
        }
      } catch (_) {
        // keep queued
      }
    }
  }

  Uri _buildMailto(FeedbackItem item) {
    final subject = '[MİHRAB] ${_categoryLabel(item.category)}';
    final body = StringBuffer()
      ..writeln(item.message)
      ..writeln()
      ..writeln('---')
      ..writeln('Kategori: ${item.category.key}')
      ..writeln('Tarih: ${item.createdAt.toIso8601String()}');
    if (item.appVersion != null) {
      body.writeln('Sürüm: ${item.appVersion}');
    }
    return Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: _encodeQuery({
        'subject': subject,
        'body': body.toString(),
      }),
    );
  }

  String _categoryLabel(FeedbackCategory c) {
    switch (c) {
      case FeedbackCategory.bug:
        return 'Hata Bildirimi';
      case FeedbackCategory.suggestion:
        return 'Öneri';
      case FeedbackCategory.prayerTimeIssue:
        return 'Namaz Vakti Sorunu';
      case FeedbackCategory.translation:
        return 'Çeviri';
      case FeedbackCategory.other:
        return 'Diğer';
    }
  }

  String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

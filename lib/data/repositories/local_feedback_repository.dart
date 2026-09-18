import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/enums/feedback_category.dart';
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
    try {
      await _local.save(item);
    } catch (e) {
      throw mapExceptionToFailure(CacheException('Feedback kaydedilemedi',
          cause: e));
    }

    var submitted = false;
    try {
      final uri = _buildMailto(item);
      submitted = await launcher(uri);
      if (submitted) {
        await _local.markSubmitted(item.id);
      }
    } catch (_) {
      // Delivery failed; item stays queued for a later flush. Not fatal.
      submitted = false;
    }

    return item.copyWith(submitted: submitted);
  }

  @override
  Future<List<FeedbackItem>> getAll() async => _local.getAll();

  @override
  Future<void> flushQueue() async {
    for (final item in _local.getUnsubmitted()) {
      try {
        final ok = await launcher(_buildMailto(item));
        if (ok) await _local.markSubmitted(item.id);
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

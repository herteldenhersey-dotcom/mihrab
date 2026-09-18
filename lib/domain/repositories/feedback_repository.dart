import '../models/feedback_model.dart';

/// Abstraction over feedback persistence + delivery.
///
/// V1: [LocalFeedbackRepository] stores in Hive and hands off via a `mailto:`
/// intent. Stubs exist for Firebase/REST so the backend can be swapped later
/// WITHOUT any UI change.
abstract class FeedbackRepository {
  /// Persists [item] locally and attempts delivery. Returns the stored item
  /// (with `submitted` reflecting the delivery attempt result).
  Future<FeedbackItem> submit(FeedbackItem item);

  /// All feedback authored on this device (newest first).
  Future<List<FeedbackItem>> getAll();

  /// Re-attempts delivery of any queued (unsubmitted) feedback.
  Future<void> flushQueue();
}

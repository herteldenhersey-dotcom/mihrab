import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/feedback_repository.dart';

/// STUB — future Firebase (Firestore) backed feedback repository.
///
/// Unimplemented in V1. Swapping [LocalFeedbackRepository] for this in the DI
/// container is the only change required; the UI stays identical.
class FirebaseFeedbackRepository implements FeedbackRepository {
  @override
  Future<List<FeedbackItem>> getAll() =>
      throw UnimplementedError('FirebaseFeedbackRepository is a Phase-2+ stub.');

  @override
  Future<void> flushQueue() =>
      throw UnimplementedError('FirebaseFeedbackRepository is a Phase-2+ stub.');

  @override
  Future<FeedbackItem> submit(FeedbackItem item) =>
      throw UnimplementedError('FirebaseFeedbackRepository is a Phase-2+ stub.');
}

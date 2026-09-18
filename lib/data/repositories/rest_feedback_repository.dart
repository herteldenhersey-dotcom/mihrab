import '../../domain/models/feedback_model.dart';
import '../../domain/repositories/feedback_repository.dart';

/// STUB — future REST backend feedback repository.
///
/// Unimplemented in V1. Provide a base URL + auth and POST feedback items;
/// keep the local Hive queue as an offline buffer.
class RestFeedbackRepository implements FeedbackRepository {
  @override
  Future<List<FeedbackItem>> getAll() =>
      throw UnimplementedError('RestFeedbackRepository is a Phase-2+ stub.');

  @override
  Future<void> flushQueue() =>
      throw UnimplementedError('RestFeedbackRepository is a Phase-2+ stub.');

  @override
  Future<FeedbackItem> submit(FeedbackItem item) =>
      throw UnimplementedError('RestFeedbackRepository is a Phase-2+ stub.');
}

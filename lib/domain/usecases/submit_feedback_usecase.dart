import '../models/feedback_model.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedbackUseCase {
  final FeedbackRepository _repository;

  SubmitFeedbackUseCase(this._repository);

  Future<FeedbackItem> call(FeedbackItem item) => _repository.submit(item);
}

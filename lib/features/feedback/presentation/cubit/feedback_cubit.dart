import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'feedback_state.dart';

/// Cubit for the Feedback feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit() : super(const FeedbackInitial());
}

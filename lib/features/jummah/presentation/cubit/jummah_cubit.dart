import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'jummah_state.dart';

/// Cubit for the Jummah feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class JummahCubit extends Cubit<JummahState> {
  JummahCubit() : super(const JummahInitial());
}

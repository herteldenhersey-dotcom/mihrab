import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'mosques_state.dart';

/// Cubit for the Mosques feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class MosquesCubit extends Cubit<MosquesState> {
  MosquesCubit() : super(const MosquesInitial());
}

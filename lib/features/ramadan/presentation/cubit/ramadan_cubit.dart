import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ramadan_state.dart';

/// Cubit for the Ramadan feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class RamadanCubit extends Cubit<RamadanState> {
  RamadanCubit() : super(const RamadanInitial());
}

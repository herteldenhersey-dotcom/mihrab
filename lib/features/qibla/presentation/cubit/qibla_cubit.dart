import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'qibla_state.dart';

/// Cubit for the Qibla feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit() : super(const QiblaInitial());
}

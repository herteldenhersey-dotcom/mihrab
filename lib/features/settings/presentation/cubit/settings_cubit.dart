import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_state.dart';

/// Cubit for the Settings feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsInitial());
}

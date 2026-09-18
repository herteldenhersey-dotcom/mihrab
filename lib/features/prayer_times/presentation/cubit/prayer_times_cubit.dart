import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'prayer_times_state.dart';

/// Cubit for the PrayerTimes feature.
///
/// Phase 1 skeleton: holds the initial state only. Business logic (usecase
/// wiring, loading/error states) is added in a later phase.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit() : super(const PrayerTimesInitial());
}

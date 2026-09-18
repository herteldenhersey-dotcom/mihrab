import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

/// Cubit for the Home dashboard.
///
/// Phase 1 skeleton. In a later phase this loads the next prayer, countdown
/// and the day's prayer list via the domain usecases.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());
}

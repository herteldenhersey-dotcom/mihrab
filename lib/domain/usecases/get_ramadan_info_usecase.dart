import '../entities/ramadan_info.dart';
import '../repositories/ramadan_repository.dart';

/// Returns [RamadanInfo] for a civil date (selected-location wall clock).
class GetRamadanInfoUseCase {
  final RamadanRepository _repo;
  const GetRamadanInfoUseCase(this._repo);

  RamadanInfo call(DateTime date, {int? adjustment}) =>
      _repo.getRamadanInfo(date, adjustment: adjustment);
}

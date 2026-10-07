import '../entities/ramadan_settings.dart';
import '../repositories/ramadan_repository.dart';

/// Loads persisted [RamadanSettings].
class GetRamadanSettingsUseCase {
  final RamadanRepository _repo;
  const GetRamadanSettingsUseCase(this._repo);

  Future<RamadanSettings> call() => _repo.loadSettings();
}

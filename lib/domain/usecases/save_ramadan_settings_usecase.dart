import '../entities/ramadan_settings.dart';
import '../repositories/ramadan_repository.dart';

/// Persists [RamadanSettings].
class SaveRamadanSettingsUseCase {
  final RamadanRepository _repo;
  const SaveRamadanSettingsUseCase(this._repo);

  Future<void> call(RamadanSettings settings) => _repo.saveSettings(settings);
}

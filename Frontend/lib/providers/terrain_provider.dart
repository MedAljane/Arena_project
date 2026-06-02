import 'package:Arena/models/models.dart';
import 'package:Arena/providers/provider_status.dart';
import 'package:Arena/services/terrain/terrain_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the terrain list for the manager's campus.
///
/// Shared between [CampusDetailScreen], [AddTerrainScreen], and
/// [CreateAgendaScreen] so terrains are fetched once per campus visit.
class TerrainProvider extends ChangeNotifier {
  List<Terrain>  _terrains = [];
  ProviderStatus _status   = ProviderStatus.initial;
  String?        _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Terrain>  get terrains  => _terrains;
  ProviderStatus get status    => _status;
  String?        get error     => _error;
  bool           get isLoading => _status == ProviderStatus.loading;

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Loads manager terrains. No-op if already loaded.
  Future<void> loadForManager(TerrainService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refresh(svc);
  }

  Future<void> refresh(TerrainService svc) async {
    _status = ProviderStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _terrains = await svc.getManagerTerrains();
      _status   = ProviderStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = ProviderStatus.error;
    }
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void addTerrain(Terrain t) {
    _terrains = [..._terrains, t];
    notifyListeners();
  }

  void removeTerrain(int id) {
    _terrains = _terrains.where((t) => t.id != id).toList();
    notifyListeners();
  }

  void updateTerrain(Terrain updated) {
    final idx = _terrains.indexWhere((t) => t.id == updated.id);
    if (idx != -1) _terrains = List.from(_terrains)..[idx] = updated;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clear() {
    _terrains = [];
    _status   = ProviderStatus.initial;
    _error    = null;
    notifyListeners();
  }
}

import 'package:Arena/models/models.dart';
import 'package:Arena/providers/provider_status.dart';
import 'package:Arena/services/campus/campus_service.dart';
import 'package:flutter/foundation.dart';

/// Holds campus data for both player (all campuses) and manager (own campus).
///
/// Shared between [PlayerDashboardScreen], manager's [CampusListScreen], and
/// [ManagerDashboardScreen] so the list is fetched once per session.
class CampusProvider extends ChangeNotifier {
  List<Campus>   _campuses  = [];
  Campus?        _myCampus;        // manager's single campus
  ProviderStatus _status    = ProviderStatus.initial;
  String?        _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Campus>   get campuses  => _campuses;
  Campus?        get myCampus  => _myCampus;
  ProviderStatus get status    => _status;
  String?        get error     => _error;
  bool           get isLoading => _status == ProviderStatus.loading;

  // ── Player ────────────────────────────────────────────────────────────────

  /// Fetches all published campuses (player view). No-op if already loaded.
  Future<void> loadAll(CampusService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refreshAll(svc);
  }

  Future<void> refreshAll(CampusService svc) async {
    _setLoading();
    try {
      _campuses = await svc.getPlayerCampuses();
      _status   = ProviderStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = ProviderStatus.error;
    }
    notifyListeners();
  }

  // ── Manager ───────────────────────────────────────────────────────────────

  /// Fetches the manager's own campus list. No-op if already loaded.
  Future<void> loadMine(CampusService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refreshMine(svc);
  }

  Future<void> refreshMine(CampusService svc) async {
    _setLoading();
    try {
      _campuses = await svc.getManagerCampuses();
      _myCampus = _campuses.isNotEmpty ? _campuses.first : null;
      _status   = ProviderStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = ProviderStatus.error;
    }
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void addCampus(Campus campus) {
    _campuses = [..._campuses, campus];
    _myCampus ??= campus;
    notifyListeners();
  }

  void removeCampus(int id) {
    _campuses = _campuses.where((c) => c.id != id).toList();
    if (_myCampus?.id == id) _myCampus = _campuses.isNotEmpty ? _campuses.first : null;
    notifyListeners();
  }

  void updateCampus(Campus updated) {
    final idx = _campuses.indexWhere((c) => c.id == updated.id);
    if (idx != -1) _campuses = List.from(_campuses)..[idx] = updated;
    if (_myCampus?.id == updated.id) _myCampus = updated;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clear() {
    _campuses = [];
    _myCampus = null;
    _status   = ProviderStatus.initial;
    _error    = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = ProviderStatus.loading;
    _error  = null;
    notifyListeners();
  }
}

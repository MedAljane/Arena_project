import 'package:Arena/models/models.dart';
import 'package:Arena/providers/provider_status.dart';
import 'package:Arena/services/manager/manager_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the authenticated manager's full profile (the Manager entity).
/// Loaded from GET /manager/me; updated via PUT /manager/me.
class ManagerProvider extends ChangeNotifier {
  Manager?       _profile;
  ProviderStatus _status = ProviderStatus.initial;
  String?        _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  Manager?       get profile  => _profile;
  ProviderStatus get status   => _status;
  String?        get error    => _error;
  bool           get isLoading => _status == ProviderStatus.loading;
  bool           get isLoaded  => _status == ProviderStatus.loaded;

  String? get nom     => _profile?.nom;
  String? get address => _profile?.address;
  String? get phone   => _profile?.phone;

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Fetches from GET /manager/me. No-op if already loaded.
  Future<void> load(ManagerService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refresh(svc);
  }

  Future<void> refresh(ManagerService svc) async {
    _status = ProviderStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _profile = await svc.getMe();
      _status  = ProviderStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = ProviderStatus.error;
    }
    notifyListeners();
  }

  // ── Mutation ──────────────────────────────────────────────────────────────

  /// Calls PUT /manager/me and updates the local profile with the response.
  Future<void> updateProfile(ManagerService svc, UpdateManagerRequest request) async {
    _profile = await svc.updateProfile(request);
    _status  = ProviderStatus.loaded;
    notifyListeners();
  }

  // ── Backfill from embedded responses ─────────────────────────────────────

  /// Called when a campus response embeds a ManagerSummary; only fills the
  /// minimal id+nom when the full profile hasn't been fetched yet.
  void setFromCampus(Campus campus) {
    if (campus.manager == null || _profile != null) return;
    _profile = Manager(id: campus.manager!.id, nom: campus.manager!.nom);
    _status  = ProviderStatus.loaded;
    notifyListeners();
  }

  /// Direct setter.
  void setProfile(Manager manager) {
    _profile = manager;
    _status  = ProviderStatus.loaded;
    _error   = null;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clear() {
    _profile = null;
    _status  = ProviderStatus.initial;
    _error   = null;
    notifyListeners();
  }
}

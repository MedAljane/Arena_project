import 'package:Arena/models/models.dart';
import 'package:Arena/providers/provider_status.dart';
import 'package:Arena/services/player/player_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the authenticated player's full profile (the Player entity).
/// Loaded from GET /player/me on the profile screen; updated via PUT /player/me.
class PlayerProvider extends ChangeNotifier {
  Player?        _profile;
  ProviderStatus _status = ProviderStatus.initial;
  String?        _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  Player?        get profile  => _profile;
  ProviderStatus get status   => _status;
  String?        get error    => _error;
  bool           get isLoading => _status == ProviderStatus.loading;
  bool           get isLoaded  => _status == ProviderStatus.loaded;

  // Convenience accessors that fall back gracefully when profile isn't loaded.
  String? get nom     => _profile?.nom;
  String? get address => _profile?.address;
  String? get phone   => _profile?.phone;

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Fetches from GET /player/me. No-op if already loaded.
  Future<void> load(PlayerService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refresh(svc);
  }

  Future<void> refresh(PlayerService svc) async {
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

  /// Calls PUT /player/me and updates the local profile with the response.
  Future<void> updateProfile(PlayerService svc, UpdatePlayerRequest request) async {
    _profile = await svc.updateProfile(request);
    _status  = ProviderStatus.loaded;
    notifyListeners();
  }

  // ── Backfill from embedded responses ─────────────────────────────────────

  /// Called when a reservation response embeds a PlayerSummary; only fills the
  /// minimal id+nom when the full profile hasn't been fetched yet.
  void setFromReservation(Reservation r) {
    if (r.player == null || _profile != null) return;
    _profile = Player(id: r.player!.id, nom: r.player!.nom);
    _status  = ProviderStatus.loaded;
    notifyListeners();
  }

  /// Direct setter — for cases where the full Player entity is already at hand.
  void setProfile(Player player) {
    _profile = player;
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

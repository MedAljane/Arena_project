import 'package:Arena/models/models.dart';
import 'package:Arena/providers/provider_status.dart';
import 'package:Arena/services/reservation/reservation_service.dart';
import 'package:flutter/foundation.dart';

/// Holds the authenticated player's full reservation list.
///
/// Used by both [PlayerBookingsScreen] and [PlayerDashboardScreen] so the
/// list is fetched once and shared — no duplicate API calls.
class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  ProviderStatus    _status       = ProviderStatus.initial;
  String?           _error;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Reservation> get reservations => _reservations;
  ProviderStatus    get status       => _status;
  String?           get error        => _error;
  bool              get isLoading    => _status == ProviderStatus.loading;

  List<Reservation> get upcoming => _reservations
      .where((r) =>
          r.statu == ReservationStatus.pending ||
          r.statu == ReservationStatus.confirmed)
      .toList();

  List<Reservation> get cancelled =>
      _reservations.where((r) => r.statu == ReservationStatus.cancelled).toList();

  /// The next confirmed/pending reservation — shown on the dashboard.
  Reservation? get nextUpcoming => upcoming.isNotEmpty ? upcoming.first : null;

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Fetches if not already loaded. Use [refresh] to force a reload.
  Future<void> load(ReservationService svc) async {
    if (_status == ProviderStatus.loaded || _status == ProviderStatus.loading) return;
    await refresh(svc);
  }

  Future<void> refresh(ReservationService svc) async {
    _status = ProviderStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _reservations = await svc.getMyReservations();
      _status       = ProviderStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = ProviderStatus.error;
    }
    notifyListeners();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Cancels a reservation and updates the list in place.
  Future<void> cancel(int id, ReservationService svc) async {
    await svc.cancelReservation(id);
    final idx = _reservations.indexWhere((r) => r.id == id);
    if (idx != -1) {
      // Replace with a cancelled copy; a full refresh re-syncs everything.
      await refresh(svc);
    }
  }

  /// Updates notes/type on a reservation and replaces the entry in the list.
  Future<Reservation?> update(
      int id, UpdateReservationRequest req, ReservationService svc) async {
    final updated = await svc.updateReservation(id, req);
    final idx     = _reservations.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reservations = List.from(_reservations)..[idx] = updated;
      notifyListeners();
    }
    return updated;
  }

  /// Adds a newly created reservation to the front of the list.
  void addReservation(Reservation r) {
    _reservations = [r, ..._reservations];
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clear() {
    _reservations = [];
    _status       = ProviderStatus.initial;
    _error        = null;
    notifyListeners();
  }
}

import 'package:Arena/models/models.dart';
import 'package:Arena/services/week_agenda/week_agenda_service.dart';
import 'package:flutter/foundation.dart';

/// Caches time-slot lists keyed by day-plan ID.
///
/// Used by [TerrainAvailabilityScreen] (player) to avoid re-fetching slots
/// when the user collapses and re-expands a day, and by [AgendaDetailScreen]
/// for the same purpose on the manager side.
///
/// Cache map convention:
///   • Key absent          → not yet requested
///   • Key present, null   → fetch in progress
///   • Key present, list   → loaded (may be empty)
class TimeSlotProvider extends ChangeNotifier {
  final Map<int, List<TimeSlot>?> _cache = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<TimeSlot>? slots(int dayPlanId)    => _cache[dayPlanId];
  bool isCached(int dayPlanId)            => _cache.containsKey(dayPlanId);
  bool isLoading(int dayPlanId)           =>
      _cache.containsKey(dayPlanId) && _cache[dayPlanId] == null;

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Fetches slots for [dayPlanId] if not already cached / loading.
  Future<void> load(int dayPlanId, WeekAgendaService svc) async {
    if (_cache.containsKey(dayPlanId)) return;
    _cache[dayPlanId] = null; // mark loading
    notifyListeners();
    try {
      final list = await svc.getTimeSlots(dayPlanId: dayPlanId);
      _cache[dayPlanId] = list;
    } catch (_) {
      _cache[dayPlanId] = [];
    }
    notifyListeners();
  }

  // ── Cache management ──────────────────────────────────────────────────────

  /// Removes a specific day plan's cache (e.g. after a booking changes slot availability).
  void invalidate(int dayPlanId) {
    _cache.remove(dayPlanId);
    notifyListeners();
  }

  /// Clears the entire cache (e.g. after navigating away from a terrain or
  /// after a successful reservation to force a fresh load).
  void invalidateAll() {
    _cache.clear();
    notifyListeners();
  }

  void clear() => invalidateAll();
}

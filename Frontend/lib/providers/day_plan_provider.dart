import 'package:Arena/models/models.dart';
import 'package:Arena/services/week_agenda/week_agenda_service.dart';
import 'package:flutter/foundation.dart';

/// Manages day-plan state for the currently viewed [AgendaDetailScreen].
///
/// Owns expand/collapse state, lazy-slot loading, and the day-plan list so
/// the screen itself becomes nearly stateless regarding this data.
///
/// Only one agenda is active at a time, so this is safe as a global provider.
class DayPlanProvider extends ChangeNotifier {
  List<DayPlan>  _dayPlans    = [];
  final Set<int> _expandedIds = {};
  final Set<int> _loadedIds   = {};
  final Set<int> _loadingIds  = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<DayPlan> get dayPlans => _dayPlans;

  bool isExpanded(int id)     => _expandedIds.contains(id);
  bool isLoaded(int id)       => _loadedIds.contains(id);
  bool isLoadingSlots(int id) => _loadingIds.contains(id);

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call when a new agenda is opened. Resets all state and seeds the list.
  void setForAgenda(List<DayPlan> plans) {
    _dayPlans    = List.from(plans);
    _expandedIds.clear();
    _loadedIds.clear();
    _loadingIds.clear();
    notifyListeners();
  }

  // ── Expand / collapse ─────────────────────────────────────────────────────

  /// Toggles a day card. On first expand, lazily loads slots via the service.
  Future<void> toggle(int id, WeekAgendaService svc) async {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
      notifyListeners();
      return;
    }
    _expandedIds.add(id);
    notifyListeners();
    if (!_loadedIds.contains(id) && !_loadingIds.contains(id)) {
      await _fetchSlots(id, svc);
    }
  }

  // ── Slot loading ──────────────────────────────────────────────────────────

  Future<void> _fetchSlots(int id, WeekAgendaService svc) async {
    _loadingIds.add(id);
    notifyListeners();
    try {
      final fresh = await svc.getDayPlanById(id);
      _applyFreshDayPlan(fresh);
      _loadedIds.add(id);
    } catch (_) {
      // Loading failed silently; card will show empty slots.
    } finally {
      _loadingIds.remove(id);
      notifyListeners();
    }
  }

  /// Re-fetches a single day plan after a slot mutation (add/edit/delete).
  Future<void> refreshDayPlan(int id, WeekAgendaService svc) async {
    try {
      final fresh = await svc.getDayPlanById(id);
      _applyFreshDayPlan(fresh);
      notifyListeners();
    } catch (_) {}
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void removeDayPlan(int id) {
    _dayPlans = _dayPlans.where((p) => p.id != id).toList();
    _expandedIds.remove(id);
    _loadedIds.remove(id);
    notifyListeners();
  }

  void _applyFreshDayPlan(DayPlan fresh) {
    final idx = _dayPlans.indexWhere((p) => p.id == fresh.id);
    if (idx != -1) _dayPlans = List.from(_dayPlans)..[idx] = fresh;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void clear() {
    _dayPlans = [];
    _expandedIds.clear();
    _loadedIds.clear();
    _loadingIds.clear();
    notifyListeners();
  }
}

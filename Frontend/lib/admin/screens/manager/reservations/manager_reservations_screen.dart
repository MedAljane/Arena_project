import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:Arena/admin/widgets/crud_modal.dart';
import 'package:flutter/material.dart';

class ManagerReservationsScreen extends StatefulWidget {
  const ManagerReservationsScreen({super.key});
  @override
  State<ManagerReservationsScreen> createState() => _ManagerReservationsScreenState();
}

class _ManagerReservationsScreenState extends State<ManagerReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _all     = [];
  bool    _loadingPending = true;
  bool    _loadingAll     = true;
  String? _errorPending;
  String? _errorAll;

  final Set<int> _processing = {};
  Map<String, dynamic>? _denyTarget;
  bool _denying = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchPending();
    _fetchAll();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _fetchPending() async {
    setState(() { _loadingPending = true; _errorPending = null; });
    try {
      final r    = await AdminClient.get('/manager/reservations/pending');
      final data = r.data;
      final list = (data is Map ? (data['data'] ?? []) : data) as List;
      if (mounted) {
        setState(() {
          _pending        = list.cast<Map<String, dynamic>>();
          _loadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorPending = AdminClient.errorMessage(e); _loadingPending = false; });
    }
  }

  Future<void> _fetchAll() async {
    setState(() { _loadingAll = true; _errorAll = null; });
    try {
      final r    = await AdminClient.get('/manager/reservations');
      final data = r.data;
      final list = (data is Map ? (data['data'] ?? []) : data) as List;
      if (mounted) {
        setState(() {
          _all        = list.cast<Map<String, dynamic>>();
          _loadingAll = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorAll = AdminClient.errorMessage(e); _loadingAll = false; });
    }
  }

  Future<void> _confirm(int id) async {
    setState(() => _processing.add(id));
    try {
      await AdminClient.put('/manager/reservations/$id/confirm', null);
      if (!mounted) return;
      _showMsg('Reservation confirmed. Chat with player created.');
      _fetchPending();
      _fetchAll();
    } catch (e) {
      if (mounted) _showMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _deny() async {
    setState(() => _denying = true);
    try {
      await AdminClient.put('/manager/reservations/${_denyTarget!['id']}/deny', null);
      if (!mounted) return;
      setState(() => _denyTarget = null);
      _showMsg('Reservation denied. Slot reactivated.');
      _fetchPending();
      _fetchAll();
    } catch (e) {
      if (mounted) _showMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _denying = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: TextStyle(
            color: isError ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AdminColors.danger : AdminColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Stack(children: [
      Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminPageHeader(
                title: 'Reservations',
                subtitle: 'Review and manage booking requests'),
            const SizedBox(height: 20),
            Container(
              height: 40,
              decoration: BoxDecoration(
                  color: ext.card, borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                    color: AdminColors.neonGreen,
                    borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                labelColor: Colors.black,
                unselectedLabelColor: ext.muted,
                tabs: [
                  Tab(text: 'Pending (${_pending.length})'),
                  Tab(text: 'All (${_all.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _ReservationList(
                rows: _pending, loading: _loadingPending,
                error: _errorPending, ext: ext, processing: _processing,
                onConfirm: _confirm,
                onDeny: (r) => setState(() => _denyTarget = r),
                showActions: true,
                emptyLabel: 'No pending requests.',
                emptyIcon: Icons.check_circle_outline,
                onRefresh: _fetchPending,
              ),
              _ReservationList(
                rows: _all, loading: _loadingAll,
                error: _errorAll, ext: ext, processing: _processing,
                onConfirm: _confirm,
                onDeny: (r) => setState(() => _denyTarget = r),
                showActions: false,
                emptyLabel: 'No reservations yet.',
                emptyIcon: Icons.calendar_today_outlined,
                onRefresh: _fetchAll,
              ),
            ],
          ),
        ),
      ]),
      if (_denyTarget != null)
        DeleteModal(
          title: 'Deny Reservation',
          description:
              'Deny this booking request? The time slot will be freed.',
          onConfirm: _deny,
          onCancel: () => setState(() => _denyTarget = null),
          deleting: _denying,
        ),
    ]);
  }
}

// ─── Reservation list ─────────────────────────────────────────────────────────

class _ReservationList extends StatelessWidget {
  const _ReservationList({
    required this.rows,
    required this.loading,
    required this.error,
    required this.ext,
    required this.processing,
    required this.onConfirm,
    required this.onDeny,
    required this.showActions,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> rows;
  final bool loading;
  final String? error;
  final AdminExt ext;
  final Set<int> processing;
  final void Function(int) onConfirm;
  final void Function(Map<String, dynamic>) onDeny;
  final bool showActions;
  final String emptyLabel;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AdminColors.neonGreen));
    }
    if (error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AdminColors.danger, size: 40),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminColors.danger, fontSize: 13)),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: onRefresh,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.indigo,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }
    if (rows.isEmpty) {
      return RefreshIndicator(
        color: AdminColors.neonGreen,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(emptyIcon, color: ext.subtle, size: 48),
                  const SizedBox(height: 14),
                  Text(emptyLabel,
                      style: TextStyle(color: ext.muted, fontSize: 14)),
                ]),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AdminColors.neonGreen,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ReservationCard(
          r: rows[i],
          ext: ext,
          processing: processing,
          onConfirm: onConfirm,
          onDeny: onDeny,
          showActions: showActions,
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.r,
    required this.ext,
    required this.processing,
    required this.onConfirm,
    required this.onDeny,
    required this.showActions,
  });

  final Map<String, dynamic> r;
  final AdminExt ext;
  final Set<int> processing;
  final void Function(int) onConfirm;
  final void Function(Map<String, dynamic>) onDeny;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final id      = r['id'] as int;
    final statu   = r['statu']?.toString() ?? 'pending';
    final type    = r['type']?.toString()  ?? 'normal';
    final terrain = r['terrain'] as Map?;
    final tType   = terrain?['Type'] ?? terrain?['type'] ?? '—';
    final player  = r['player'] as Map?;
    final pName   = player?['nom']?.toString() ?? 'Player #${player?['id']}';
    final slot    = r['time_slot'] as Map?;
    final timeLbl = slot != null
        ? '${slot['startTime']} – ${slot['endTime']}'
        : '—';
    final dp      = slot?['day_plan'] as Map?;
    final dayLbl  = dp != null
        ? '${dp['dayOfWeek']}  ·  ${dp['date'] ?? ''}'
        : '—';

    final statusColor = switch (statu) {
      'confirmed' => AdminColors.neonGreen,
      'cancelled' => AdminColors.danger,
      _           => AdminColors.warning,
    };
    final isPending = statu == 'pending';
    final isUrgent  = type == 'urgent';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        ext.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AdminColors.warning.withValues(alpha: 0.4)
              : ext.border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AdminColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.35)),
            ),
            child: Text(tType.toString(),
                style: const TextStyle(
                    color: AdminColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          if (isUrgent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('URGENT',
                  style: TextStyle(
                      color: AdminColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              statu[0].toUpperCase() + statu.substring(1),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(color: ext.border, height: 1),
        const SizedBox(height: 10),
        Wrap(spacing: 20, runSpacing: 6, children: [
          _Pill(icon: Icons.person_outline,         label: pName),
          _Pill(icon: Icons.access_time,             label: timeLbl),
          _Pill(icon: Icons.calendar_today_outlined, label: dayLbl),
        ]),
        if (r['notes'] != null &&
            (r['notes'] as String).isNotEmpty) ...[
          const SizedBox(height: 6),
          _Pill(icon: Icons.notes_outlined, label: r['notes'].toString()),
        ],
        if (isPending && showActions) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    processing.contains(id) ? null : () => onDeny(r),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AdminColors.danger.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text('Deny',
                    style: TextStyle(
                        color: AdminColors.danger,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: processing.contains(id)
                    ? null
                    : () => onConfirm(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.neonGreen,
                  disabledBackgroundColor:
                      AdminColors.neonGreen.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                ),
                child: Text(
                  processing.contains(id) ? 'Confirming…' : 'Confirm',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: context.adminExt.muted),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: context.adminExt.muted, fontSize: 12)),
      ]);
}

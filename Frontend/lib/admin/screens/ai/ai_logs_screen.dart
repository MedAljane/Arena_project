import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiLogsScreen extends StatefulWidget {
  const AiLogsScreen({super.key});
  @override
  State<AiLogsScreen> createState() => _AiLogsScreenState();
}

class _AiLogsScreenState extends State<AiLogsScreen> {
  // ── Stats state ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _stats;
  bool    _statsLoading = true;
  String? _statsError;

  // ── Logs state ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _logs     = [];
  bool    _logsLoading = true;
  String? _logsError;
  int     _total      = 0;

  // ── Filters ───────────────────────────────────────────────────────────────
  String _search     = '';
  String _roleFilter = ''; // '' | 'player' | 'manager'
  bool   _errorsOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchLogs();
  }

  Future<void> _fetchStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      final r = await AdminClient.get('/admin/ai-stats');
      if (mounted) setState(() { _stats = r.data as Map<String, dynamic>; _statsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _statsError = AdminClient.errorMessage(e); _statsLoading = false; });
    }
  }

  Future<void> _fetchLogs() async {
    setState(() { _logsLoading = true; _logsError = null; });
    try {
      final params = StringBuffer('/admin/ai-assisstant-chat-log?limit=100');
      if (_search.isNotEmpty)   params.write('&search=${Uri.encodeComponent(_search)}');
      if (_roleFilter.isNotEmpty) params.write('&role=$_roleFilter');
      if (_errorsOnly)          params.write('&errors=true');
      final r    = await AdminClient.get(params.toString());
      final body = r.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _logs        = ((body['data'] as List?) ?? []).cast<Map<String, dynamic>>();
          _total       = (body['meta']?['total'] as int?) ?? _logs.length;
          _logsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _logsError = AdminClient.errorMessage(e); _logsLoading = false; });
    }
  }

  void _applyFilters() {
    _fetchLogs();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _fmtMs(dynamic v) {
    final ms = (v as num?)?.toDouble() ?? 0;
    return ms < 1000 ? '${ms.round()} ms' : '${(ms / 1000).toStringAsFixed(1)} s';
  }

  static String _fmtTs(dynamic v) {
    if (v == null) return '—';
    final dt = v is DateTime ? v : DateTime.tryParse(v.toString());
    if (dt == null) return '—';
    final l = dt.toLocal();
    return '${l.month.toString().padLeft(2,'0')}/${l.day.toString().padLeft(2,'0')} '
        '${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return RefreshIndicator(
      color: AdminColors.neonGreen,
      onRefresh: () async { await _fetchStats(); await _fetchLogs(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title:    'AI Analytics',
              subtitle: 'Usage statistics and interaction logs for the AI assistant',
            ),
            const SizedBox(height: 28),

            // ── Stat cards ─────────────────────────────────────────────────
            if (_statsLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AdminColors.neonGreen)))
            else if (_statsError != null)
              _ErrorBanner(message: _statsError!, onRetry: _fetchStats)
            else if (_stats != null) ...[
              _StatCardsRow(stats: _stats!),
              const SizedBox(height: 28),
              _ChartsRow(stats: _stats!),
              const SizedBox(height: 28),
            ],

            // ── Logs table ─────────────────────────────────────────────────
            Row(children: [
              Text('Interaction Logs',
                  style: TextStyle(color: ext.text, fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('$_total entries',
                  style: TextStyle(color: ext.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            _LogFilters(
              search:     _search,
              roleFilter: _roleFilter,
              errorsOnly: _errorsOnly,
              onSearch:   (v) => setState(() { _search = v; }),
              onRole:     (v) => setState(() { _roleFilter = v; }),
              onErrors:   (v) => setState(() { _errorsOnly = v; }),
              onApply:    _applyFilters,
            ),
            const SizedBox(height: 14),
            if (_logsLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AdminColors.neonGreen)))
            else if (_logsError != null)
              _ErrorBanner(message: _logsError!, onRetry: _fetchLogs)
            else if (_logs.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.smart_toy_outlined, color: ext.subtle, size: 48),
                  const SizedBox(height: 14),
                  Text('No logs yet.', style: TextStyle(color: ext.muted, fontSize: 15)),
                ]),
              ))
            else
              _LogsTable(logs: _logs, fmtMs: _fmtMs, fmtTs: _fmtTs),
          ],
        ),
      ),
    );
  }
}

// ─── Stat cards row ───────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final ov   = stats['overview']    as Map<String, dynamic>? ?? {};
    final perf = stats['performance'] as Map<String, dynamic>? ?? {};
    final conv = stats['conversion']  as Map<String, dynamic>? ?? {};

    final cards = [
      _StatCard(value: '${ov['total']     ?? 0}', label: 'Total Interactions',  color: AdminColors.indigo,   icon: Icons.smart_toy_outlined),
      _StatCard(value: '${ov['successRate'] ?? 0}%', label: 'Success Rate',     color: AdminColors.neonGreen, icon: Icons.check_circle_outline),
      _StatCard(value: '${ov['playerTotal'] ?? 0}', label: 'Player Sessions',   color: AdminColors.sky,       icon: Icons.person_outline),
      _StatCard(value: '${ov['managerTotal'] ?? 0}', label: 'Manager Sessions', color: AdminColors.violet,    icon: Icons.manage_accounts_outlined),
      _StatCard(value: _fmtMs(perf['avgProcessingMs']), label: 'Avg Response',  color: AdminColors.amber,     icon: Icons.timer_outlined),
      _StatCard(value: '${conv['bookingConversionPct'] ?? 0}%', label: 'Booking Conversion', color: AdminColors.emerald, icon: Icons.sports_soccer_outlined),
    ];

    final w = MediaQuery.of(context).size.width;
    final cols = w > 1100 ? 6 : (w > 800 ? 3 : 2);

    return GridView.count(
      crossAxisCount:   cols,
      crossAxisSpacing: 14,
      mainAxisSpacing:  14,
      childAspectRatio: 1.9,
      shrinkWrap:       true,
      physics:          const NeverScrollableScrollPhysics(),
      children:         cards,
    );
  }

  static String _fmtMs(dynamic v) {
    final ms = (v as num?)?.toDouble() ?? 0;
    return ms < 1000 ? '${ms.round()} ms' : '${(ms / 1000).toStringAsFixed(1)} s';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label,
      required this.color, required this.icon});
  final String value; final String label;
  final Color color; final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: ext.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 15)),
        const SizedBox(height: 10),
        Text(value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
                color: ext.text, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: ext.muted, fontSize: 11)),
      ]),
    );
  }
}

// ─── Charts row ───────────────────────────────────────────────────────────────

class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final side  = w > 900;

    Widget dailyChart = _DailyActivityChart(
        activity: (stats['dailyActivity'] as List?)?.cast<Map<String, dynamic>>() ?? []);
    Widget breakdown  = _BreakdownPanel(stats: stats);

    if (side) {
      return IntrinsicHeight(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: dailyChart),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: breakdown),
        ],
      ));
    }
    return Column(children: [
      dailyChart, const SizedBox(height: 16), breakdown]);
  }
}

// ─── Daily activity bar chart ─────────────────────────────────────────────────

class _DailyActivityChart extends StatelessWidget {
  const _DailyActivityChart({required this.activity});
  final List<Map<String, dynamic>> activity;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    final items = activity.length > 14
        ? activity.sublist(activity.length - 14)
        : activity;
    final maxVal = items.fold<int>(1, (m, e) => (e['total'] as int? ?? 0) > m
        ? (e['total'] as int) : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ext.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Daily Activity (last 14 days)',
            style: TextStyle(color: ext.text, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Total AI interactions per day',
            style: TextStyle(color: ext.muted, fontSize: 11)),
        const SizedBox(height: 20),
        if (items.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Text('No data yet.', style: TextStyle(color: ext.subtle))))
        else
          ...items.map((item) {
            final total   = item['total']  as int? ?? 0;
            final player  = item['player'] as int? ?? 0;
            final date    = (item['date'] as String? ?? '').substring(5); // MM-DD
            final frac    = total / maxVal;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(width: 38,
                    child: Text(date, style: TextStyle(color: ext.muted, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stacked bar
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: SizedBox(height: 12,
                        child: LayoutBuilder(builder: (ctx, c) {
                          final totalW = c.maxWidth * frac;
                          final pW     = total == 0 ? 0.0 : totalW * player / total;
                          final mW     = totalW - pW;
                          return Row(children: [
                            if (pW > 0) Container(width: pW, color: AdminColors.sky),
                            if (mW > 0) Container(width: mW, color: AdminColors.violet),
                            Expanded(child: Container(color: ext.border.withValues(alpha: 0.4))),
                          ]);
                        }),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 8),
                SizedBox(width: 28,
                    child: Text('$total',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: ext.text, fontSize: 11,
                            fontWeight: FontWeight.w600))),
              ]),
            );
          }),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [
            _Legend(color: AdminColors.sky,    label: 'Player'),
            const SizedBox(width: 16),
            _Legend(color: AdminColors.violet, label: 'Manager'),
          ]),
        ],
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color; final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: context.adminExt.muted, fontSize: 11)),
      ]);
}

// ─── Provider + tools breakdown ───────────────────────────────────────────────

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final ext      = context.adminExt;
    final byProv   = stats['byProvider']   as Map<String, dynamic>? ?? {};
    final topTools = (stats['topTools'] as List?)
            ?.cast<Map<String, dynamic>>()
            .take(8)
            .toList() ?? [];
    final total    = byProv.values.fold<int>(0, (s, v) => s + (v as int));
    final maxTool  = topTools.isEmpty ? 1 :
        topTools.map((t) => t['count'] as int? ?? 0).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ext.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Provider breakdown
        Text('Providers', style: TextStyle(
            color: ext.text, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (byProv.isEmpty)
          Text('No data.', style: TextStyle(color: ext.subtle, fontSize: 12))
        else
          ...byProv.entries.map((e) {
            final frac = total == 0 ? 0.0 : (e.value as int) / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(e.key, style: TextStyle(
                      color: ext.text, fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('${(frac * 100).round()}%',
                      style: TextStyle(color: ext.muted, fontSize: 11)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           frac,
                    minHeight:       7,
                    backgroundColor: ext.border.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(AdminColors.indigo),
                  ),
                ),
              ]),
            );
          }),

        const Divider(height: 28, color: Colors.white10),

        // Top tools
        Text('Top Tools', style: TextStyle(
            color: ext.text, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (topTools.isEmpty)
          Text('No data.', style: TextStyle(color: ext.subtle, fontSize: 12))
        else
          ...topTools.map((t) {
            final name  = t['tool']  as String? ?? '';
            final count = t['count'] as int?    ?? 0;
            final frac  = count / maxTool;
            final label = name.replaceAllMapped(
                RegExp(r'(?<=[a-z])([A-Z])'), (m) => ' ${m[1]}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(flex: 4,
                  child: Text(label, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ext.text, fontSize: 11))),
                const SizedBox(width: 8),
                Expanded(flex: 3,
                  child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac, minHeight: 7,
                      backgroundColor: ext.border.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AdminColors.neonGreen.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(width: 24,
                    child: Text('$count', textAlign: TextAlign.right,
                        style: TextStyle(color: ext.muted, fontSize: 10))),
              ]),
            );
          }),
      ]),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.search, required this.roleFilter,
    required this.errorsOnly, required this.onSearch,
    required this.onRole, required this.onErrors, required this.onApply,
  });
  final String search, roleFilter;
  final bool errorsOnly;
  final ValueChanged<String> onSearch, onRole;
  final ValueChanged<bool>   onErrors;
  final VoidCallback         onApply;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Row(children: [
      // Search input
      SizedBox(height: 36, width: 220,
        child: TextField(
          onChanged:   onSearch,
          onSubmitted: (_) => onApply(),
          style:       TextStyle(color: ext.text, fontSize: 13),
          decoration: InputDecoration(
            hintText:       'Search messages…',
            hintStyle:      TextStyle(color: ext.subtle, fontSize: 12),
            prefixIcon:     Icon(Icons.search, size: 14, color: ext.subtle),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            filled: true, fillColor: ext.card,
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.border)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AdminColors.indigo, width: 1.5)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      // Role + error chips — horizontal row
      _FilterChip(label: 'All',      active: roleFilter == '',       onTap: () { onRole('');       onApply(); }),
      const SizedBox(width: 6),
      _FilterChip(label: 'Players',  active: roleFilter == 'player', onTap: () { onRole('player'); onApply(); }, color: AdminColors.sky),
      const SizedBox(width: 6),
      _FilterChip(label: 'Managers', active: roleFilter == 'manager',onTap: () { onRole('manager');onApply(); }, color: AdminColors.violet),
      const SizedBox(width: 6),
      _FilterChip(label: 'Errors',   active: errorsOnly,             onTap: () { onErrors(!errorsOnly); onApply(); }, color: AdminColors.danger),
    ]);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active,
      required this.onTap, this.color});
  final String label; final bool active;
  final VoidCallback onTap; final Color? color;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    final c   = color ?? AdminColors.indigo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        active ? c.withValues(alpha: 0.15) : ext.card,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: active ? c : ext.border,
              width: active ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(color: active ? c : ext.muted, fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ─── Logs table ───────────────────────────────────────────────────────────────

class _LogsTable extends StatelessWidget {
  const _LogsTable({required this.logs, required this.fmtMs, required this.fmtTs});
  final List<Map<String, dynamic>> logs;
  final String Function(dynamic) fmtMs;
  final String Function(dynamic) fmtTs;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(color: ext.card,
            border: Border.all(color: ext.border),
            borderRadius: BorderRadius.circular(14)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 120),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(130),   // Date
                1: FixedColumnWidth(100),   // Role — fits "manager" without wrapping
                2: FixedColumnWidth(100),   // Provider
                3: FlexColumnWidth(3),      // Message
                4: FixedColumnWidth(65),    // Tools #
                5: FixedColumnWidth(95),    // Time
                6: FixedColumnWidth(70),    // Status
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: ext.border))),
                  children: [
                    _th('Date',     ext), _th('Role', ext), _th('Provider', ext),
                    _th('Message',  ext), _th('Tools', ext),
                    _th('Time',     ext), _th('Status', ext),
                  ],
                ),
                // Rows
                ...logs.map((log) {
                  final success   = log['success'] as bool? ?? true;
                  final role      = log['userRole'] as String? ?? '';
                  final tools     = (log['toolsUsed'] as List?)?.length ?? 0;
                  final msg       = log['userMessage'] as String? ?? '';
                  final roleColor = role == 'player' ? AdminColors.sky : AdminColors.violet;

                  return TableRow(
                    decoration: BoxDecoration(
                        border: Border(bottom:
                            BorderSide(color: ext.border.withValues(alpha: 0.4)))),
                    children: [
                      _td(Text(fmtTs(log['createdAtTimestamp']),
                          style: TextStyle(color: ext.muted, fontSize: 11))),
                      _td(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor.withValues(alpha: 0.35))),
                        child: Text(role,
                            maxLines:  1,
                            softWrap:  false,
                            overflow:  TextOverflow.clip,
                            style: TextStyle(
                                color: roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
                      )),
                      _td(Text(log['provider'] as String? ?? '—',
                          style: TextStyle(color: ext.muted, fontSize: 11))),
                      _td(Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: ext.text, fontSize: 12))),
                      _td(Text('$tools',
                          style: TextStyle(color: ext.muted, fontSize: 12))),
                      _td(Text(fmtMs(log['processingMs']),
                          style: TextStyle(color: ext.muted, fontSize: 11))),
                      _td(Icon(
                          success ? Icons.check_circle_outline : Icons.error_outline,
                          size: 16,
                          color: success ? AdminColors.neonGreen : AdminColors.danger)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableCell _th(String label, AdminExt ext) => TableCell(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Text(label.toUpperCase(),
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(color: ext.muted, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    ),
  );

  TableCell _td(Widget child) => TableCell(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: child,
    ),
  );
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message; final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin:  const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
        color: AdminColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.danger.withValues(alpha: 0.4))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AdminColors.danger, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message,
          style: const TextStyle(color: AdminColors.danger, fontSize: 13))),
      TextButton(onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: AdminColors.danger))),
    ]),
  );
}

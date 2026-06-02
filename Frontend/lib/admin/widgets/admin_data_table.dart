import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';

// ─── Column definition ────────────────────────────────────────────────────────

class AdminColumn {
  const AdminColumn(this.key, this.label, {this.flex = 1, this.mono = false});
  final String key;
  final String label;
  final int    flex;
  final bool   mono;
}

// ─── Main table widget ────────────────────────────────────────────────────────

class AdminDataTable extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.loading    = false,
    this.error,
    this.emptyLabel = 'No data found.',
    this.searchFields = const [],
    this.onEdit,
    this.onDelete,
    this.cellBuilder,
  });

  final List<AdminColumn>                       columns;
  final List<Map<String, dynamic>>              rows;
  final bool                                    loading;
  final String?                                 error;
  final String                                  emptyLabel;
  final List<String>                            searchFields;
  final void Function(Map<String, dynamic>)?    onEdit;
  final void Function(Map<String, dynamic>)?    onDelete;
  /// Override cell rendering for specific column keys.
  final Widget? Function(String key, dynamic value, Map<String, dynamic> row)?
      cellBuilder;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  String _search = '';
  late Map<String, bool> _vis;

  @override
  void initState() {
    super.initState();
    _vis = {for (final c in widget.columns) c.key: true};
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return widget.rows;
    final q = _search.toLowerCase();
    return widget.rows.where((row) {
      for (final f in widget.searchFields) {
        if (row[f]?.toString().toLowerCase().contains(q) == true) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ext    = context.adminExt;
    final hasAct = widget.onEdit != null || widget.onDelete != null;
    final visCols = widget.columns.where((c) => _vis[c.key] == true).toList();
    final rows   = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Controls ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _SearchBar(value: _search, onChanged: (v) => setState(() => _search = v))),
            const SizedBox(width: 10),
            _ColumnToggler(columns: widget.columns, visible: _vis,
                onToggle: (k) => setState(() => _vis[k] = !(_vis[k] ?? true))),
          ],
        ),
        const SizedBox(height: 12),

        // ── Table ────────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color:  ext.card,
              border: Border.all(color: ext.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.loading
                ? const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AdminColors.neonGreen, strokeWidth: 2)))
                : widget.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(60),
                        child: Center(child: Text(widget.error!,
                            style: const TextStyle(
                                color: AdminColors.danger, fontSize: 13))))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 320),
                          child: Table(
                            columnWidths: {
                              for (int i = 0; i < visCols.length; i++)
                                i: FlexColumnWidth(visCols[i].flex.toDouble()),
                              if (hasAct)
                                visCols.length: const FixedColumnWidth(140),
                            },
                            children: [
                              // Header row
                              TableRow(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(color: ext.border))),
                                children: [
                                  ...visCols.map((c) => _th(c.label, ext)),
                                  if (hasAct) _th('Actions', ext),
                                ],
                              ),
                              // Data rows
                              if (rows.isEmpty)
                                TableRow(children: [
                                  ...List.generate(
                                      visCols.length + (hasAct ? 1 : 0),
                                      (_) => TableCell(child: Container())),
                                ]),
                              ...rows.map((row) => TableRow(
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: ext.border
                                                    .withValues(alpha: 0.5)))),
                                    children: [
                                      ...visCols.map((c) {
                                        final custom = widget.cellBuilder
                                            ?.call(c.key, row[c.key], row);
                                        return TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 14),
                                            child: custom ??
                                                _defaultCell(
                                                    row[c.key], c.mono, ext),
                                          ),
                                        );
                                      }),
                                      if (hasAct)
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (widget.onEdit != null)
                                                  _actionBtn('Edit',
                                                      AdminColors.indigo,
                                                      () => widget.onEdit!(row)),
                                                if (widget.onDelete != null) ...[
                                                  const SizedBox(width: 6),
                                                  _actionBtn('Delete',
                                                      AdminColors.danger,
                                                      () => widget.onDelete!(row)),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
          ),
        ),

        // Empty message (outside table to avoid Table layout issues)
        if (!widget.loading && widget.error == null && rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _search.isNotEmpty
                    ? 'No results for "$_search".'
                    : widget.emptyLabel,
                style: TextStyle(color: ext.subtle, fontSize: 13),
              ),
            ),
          ),

        // Row count
        if (!widget.loading && widget.error == null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('${rows.length} ${rows.length == 1 ? "row" : "rows"}${_search.isNotEmpty ? " found" : " total"}',
                style: TextStyle(color: ext.subtle, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _th(String label, AdminExt ext) => TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
                color:       ext.muted,
                fontSize:    11,
                fontWeight:  FontWeight.w600,
                letterSpacing: 0.8),
          ),
        ),
      );

  Widget _defaultCell(dynamic value, bool mono, AdminExt ext) {
    if (value == null || value.toString().isEmpty) {
      return Text('—', style: TextStyle(color: ext.subtle, fontSize: 14));
    }
    return Text(
      value.toString(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color:      ext.text,
        fontSize:   13,
        fontFamily: mono ? 'monospace' : null,
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged:   onChanged,
        style:       TextStyle(color: ext.text, fontSize: 14),
        decoration: InputDecoration(
          hintText:       'Search…',
          hintStyle:      TextStyle(color: ext.subtle, fontSize: 14),
          prefixIcon:     Icon(Icons.search, size: 18, color: ext.subtle),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled:         true,
          fillColor:      ext.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide(color: ext.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:   BorderSide(color: ext.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AdminColors.indigo, width: 1.5),
          ),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon:    Icon(Icons.close, size: 16, color: ext.subtle),
                  onPressed: () => onChanged(''))
              : null,
        ),
      ),
    );
  }
}

// ─── Column toggler ───────────────────────────────────────────────────────────

class _ColumnToggler extends StatelessWidget {
  const _ColumnToggler({
    required this.columns,
    required this.visible,
    required this.onToggle,
  });
  final List<AdminColumn>   columns;
  final Map<String, bool>   visible;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final ext    = context.adminExt;
    final hidden = columns.where((c) => visible[c.key] == false).length;

    return PopupMenuButton<String>(
      tooltip:     'Toggle columns',
      color:        ext.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:         BorderSide(color: ext.border),
      ),
      itemBuilder: (_) => columns
          .map((c) => PopupMenuItem<String>(
                value: c.key,
                onTap: () => onToggle(c.key),
                child: Row(
                  children: [
                    Icon(
                      visible[c.key] == true
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size:  18,
                      color: visible[c.key] == true
                          ? AdminColors.neonGreen
                          : ext.subtle,
                    ),
                    const SizedBox(width: 8),
                    Text(c.label,
                        style: TextStyle(color: ext.text, fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:        ext.card,
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: ext.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_column_outlined, size: 16, color: ext.muted),
            const SizedBox(width: 6),
            Text('Columns',
                style: TextStyle(color: ext.muted, fontSize: 13)),
            if (hidden > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                    color: AdminColors.indigo, shape: BoxShape.circle),
                child: Center(
                  child: Text('$hidden',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

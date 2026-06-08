import 'package:Arena/admin/api/admin_client.dart';
import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:Arena/admin/widgets/admin_page_header.dart';
import 'package:flutter/material.dart';

class AiConfigScreen extends StatefulWidget {
  const AiConfigScreen({super.key});
  @override
  State<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends State<AiConfigScreen> {
  Map<String, dynamic>? _player;
  Map<String, dynamic>? _manager;
  bool    _loading = true;
  String? _error;
  int     _generation = 0; // bumps when data is (re)loaded, forces card state to reset

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r    = await AdminClient.get('/admin/ai-config');
      final body = r.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _player     = (body['Player']  as Map<String, dynamic>?) ?? {};
          _manager    = (body['Manager'] as Map<String, dynamic>?) ?? {};
          _loading    = false;
          _generation++;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminColors.neonGreen,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              title:    'AI Assistant Config',
              subtitle: 'Tune the model, generation limits, and behavior of the Player and Manager AI assistants',
            ),
            const SizedBox(height: 28),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AdminColors.neonGreen),
              ))
            else if (_error != null)
              _ErrorBanner(message: _error!, onRetry: _fetch)
            else ...[
              _AssistantConfigCard(
                key:     ValueKey('player-$_generation'),
                role:    'Player',
                icon:    Icons.sports_soccer_outlined,
                config:  _player!,
                onSaved: _fetch,
              ),
              const SizedBox(height: 24),
              _AssistantConfigCard(
                key:     ValueKey('manager-$_generation'),
                role:    'Manager',
                icon:    Icons.manage_accounts_outlined,
                config:  _manager!,
                onSaved: _fetch,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Config card (one per role) ───────────────────────────────────────────────

class _AssistantConfigCard extends StatefulWidget {
  const _AssistantConfigCard({
    super.key,
    required this.role,
    required this.icon,
    required this.config,
    required this.onSaved,
  });

  final String role; // 'Player' | 'Manager'
  final IconData icon;
  final Map<String, dynamic> config;
  final VoidCallback onSaved;

  @override
  State<_AssistantConfigCard> createState() => _AssistantConfigCardState();
}

class _AssistantConfigCardState extends State<_AssistantConfigCard> {
  static const _providers   = ['gemini', 'openai', 'ollama'];
  static const _toolChoices = ['auto', 'required', 'none'];

  late String _provider;
  late final TextEditingController _model;
  late final TextEditingController _temperature;
  late final TextEditingController _maxTokens;
  late final TextEditingController _maxSteps;

  // Advanced (optional — left blank means "use the AI SDK default")
  late final TextEditingController _topP;
  late final TextEditingController _topK;
  late final TextEditingController _presencePenalty;
  late final TextEditingController _frequencyPenalty;
  late final TextEditingController _stopSequences;
  late final TextEditingController _seed;
  late final TextEditingController _maxRetries;
  String? _toolChoice;

  bool _advancedOpen = false;
  bool _saving       = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    _provider    = _providers.contains(c['provider']) ? c['provider'] as String : 'gemini';
    _model       = TextEditingController(text: c['model']?.toString() ?? '');
    _temperature = TextEditingController(text: _fmt(c['temperature']));
    _maxTokens   = TextEditingController(text: _fmt(c['maxTokens']));
    _maxSteps    = TextEditingController(text: _fmt(c['maxSteps']));

    _topP             = TextEditingController(text: _fmt(c['topP']));
    _topK             = TextEditingController(text: _fmt(c['topK']));
    _presencePenalty  = TextEditingController(text: _fmt(c['presencePenalty']));
    _frequencyPenalty = TextEditingController(text: _fmt(c['frequencyPenalty']));
    _stopSequences    = TextEditingController(
        text: (c['stopSequences'] as List?)?.join(', ') ?? '');
    _seed       = TextEditingController(text: _fmt(c['seed']));
    _maxRetries = TextEditingController(text: _fmt(c['maxRetries']));
    _toolChoice = _toolChoices.contains(c['toolChoice']) ? c['toolChoice'] as String : null;
  }

  static String _fmt(dynamic v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    for (final c in [
      _model, _temperature, _maxTokens, _maxSteps,
      _topP, _topK, _presencePenalty, _frequencyPenalty,
      _stopSequences, _seed, _maxRetries,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  num? _num(String text) => text.trim().isEmpty ? null : num.tryParse(text.trim());
  int? _int(String text) => text.trim().isEmpty ? null : int.tryParse(text.trim());

  Future<void> _save() async {
    if (_model.text.trim().isEmpty) {
      setState(() => _error = 'Model is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final stops = _stopSequences.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final payload = <String, dynamic>{
      'provider':    _provider,
      'model':       _model.text.trim(),
      'temperature': _num(_temperature.text),
      'maxTokens':   _int(_maxTokens.text),
      'maxSteps':    _int(_maxSteps.text),
      'topP':             _num(_topP.text),
      'topK':             _int(_topK.text),
      'presencePenalty':  _num(_presencePenalty.text),
      'frequencyPenalty': _num(_frequencyPenalty.text),
      'stopSequences':    stops.isEmpty ? null : stops,
      'seed':             _int(_seed.text),
      'maxRetries':       _int(_maxRetries.text),
      'toolChoice':       _toolChoice,
    };

    try {
      await AdminClient.put('/admin/ai-config/${widget.role}', payload);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('${widget.role} assistant config saved.'),
        backgroundColor: AdminColors.neonGreen,
      ));
    } catch (e) {
      if (mounted) setState(() { _error = AdminClient.errorMessage(e); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext   = context.adminExt;
    final color = widget.role == 'Player' ? AdminColors.emerald : AdminColors.indigo;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        ext.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(widget.icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Text('${widget.role} Assistant',
                style: TextStyle(color: ext.text, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),

          if (_error != null) ...[
            _InlineErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],

          // ── Common config (always visible, required) ─────────────────────
          _FieldGrid(children: [
            _Dropdown(
              label: 'Provider', value: _provider, options: _providers,
              onChanged: (v) => setState(() => _provider = v),
            ),
            _TextInput(label: 'Model', controller: _model,
                hint: 'e.g. gemini-2.5-flash'),
            _TextInput(label: 'Temperature', controller: _temperature,
                hint: '0.0 – 2.0', keyboardType: TextInputType.number),
            _TextInput(label: 'Max tokens', controller: _maxTokens,
                hint: 'Response length cap', keyboardType: TextInputType.number),
            _TextInput(label: 'Max steps', controller: _maxSteps,
                hint: 'Tool-call round trips', keyboardType: TextInputType.number),
          ]),

          const SizedBox(height: 16),

          // ── Advanced config (collapsible, optional) ──────────────────────
          InkWell(
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(_advancedOpen ? Icons.expand_less : Icons.expand_more,
                    color: ext.muted, size: 20),
                const SizedBox(width: 6),
                Text('Advanced settings',
                    style: TextStyle(color: ext.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('(leave blank to use AI SDK defaults)',
                    style: TextStyle(color: ext.subtle, fontSize: 12)),
              ]),
            ),
          ),
          if (_advancedOpen) ...[
            const SizedBox(height: 8),
            _FieldGrid(children: [
              _TextInput(label: 'Top P', controller: _topP,
                  hint: '0.0 – 1.0', keyboardType: TextInputType.number),
              _TextInput(label: 'Top K', controller: _topK,
                  hint: 'Integer', keyboardType: TextInputType.number),
              _TextInput(label: 'Presence penalty', controller: _presencePenalty,
                  hint: '-2.0 – 2.0', keyboardType: TextInputType.number),
              _TextInput(label: 'Frequency penalty', controller: _frequencyPenalty,
                  hint: '-2.0 – 2.0', keyboardType: TextInputType.number),
              _TextInput(label: 'Seed', controller: _seed,
                  hint: 'Integer (reproducibility)', keyboardType: TextInputType.number),
              _TextInput(label: 'Max retries', controller: _maxRetries,
                  hint: 'Integer', keyboardType: TextInputType.number),
              _Dropdown(
                label: 'Tool choice', value: _toolChoice, options: _toolChoices,
                placeholder: 'SDK default (auto)',
                onChanged: (v) => setState(() => _toolChoice = v),
              ),
              _TextInput(label: 'Stop sequences', controller: _stopSequences,
                  hint: 'Comma-separated, e.g. END, ###'),
            ]),
          ],

          const SizedBox(height: 20),

          // ── Save ──────────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                elevation: 0,
              ),
              child: Text(_saving ? 'Saving…' : 'Save changes',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared form helpers ──────────────────────────────────────────────────────

/// Lays fields out in a responsive grid: ~260px-wide cells that wrap.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing:   16,
        runSpacing: 16,
        children: children
            .map((w) => SizedBox(width: 260, child: w))
            .toList(),
      );
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ext.muted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller:   controller,
          keyboardType: keyboardType,
          style:        TextStyle(color: ext.text, fontSize: 14),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: TextStyle(color: ext.subtle, fontSize: 13),
            filled:    true,
            fillColor: ext.input,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide:   const BorderSide(color: AdminColors.indigo, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String? placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ext.muted, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color:        ext.input,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: ext.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:        value,
              isExpanded:   true,
              dropdownColor: ext.card,
              hint: placeholder == null ? null
                  : Text(placeholder!, style: TextStyle(color: ext.subtle, fontSize: 14)),
              items: options
                  .map((o) => DropdownMenuItem(value: o,
                      child: Text(o, style: TextStyle(color: ext.text, fontSize: 14))))
                  .toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Error banners ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
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

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        AdminColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: AdminColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AdminColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: const TextStyle(color: AdminColors.danger, fontSize: 13))),
        ]),
      );
}

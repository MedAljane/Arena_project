import 'dart:math';
import 'package:Arena/models/ai/ai_chat.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerAiScreen extends StatefulWidget {
  const ManagerAiScreen({super.key});

  @override
  State<ManagerAiScreen> createState() => _ManagerAiScreenState();
}

class _ManagerAiScreenState extends State<ManagerAiScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _loading = false;

  final String _sessionId = _genId();

  static String _genId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static const _suggestions = [
    'Fill the agendas of the upcoming 4 weeks for the Football terrain',
    'Remove all time slots from day_off days in my published agendas',
    'Confirm all pending reservations',
    'Create and publish a week agenda for Tennis starting next Monday',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty || _loading) return;
    _ctrl.clear();

    final userMsg = AiChatMessage(
        role: 'user', content: msg, timestamp: DateTime.now());
    setState(() { _messages.add(userMsg); _loading = true; });
    _scrollToBottom();

    try {
      final svc      = context.read<AiService>();
      final history  = _messages
          .where((m) => m != userMsg)
          .take(40)
          .toList();
      final response = await svc.managerChat(msg, history, _sessionId);

      if (!mounted) return;
      final aiMsg = AiChatMessage(
        role:      'assistant',
        content:   response.reply,
        timestamp: DateTime.now(),
        actions:   response.actionsPerformed,
      );
      setState(() { _messages.add(aiMsg); _loading = false; });
      _scrollToBottom();
    } on ServiceException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Unexpected error. Please try again.');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
              child: Row(children: [
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(width: 40, height: 40,
                      child: Center(child: FaIcon(
                          FontAwesomeIcons.arrowLeft,
                          color: AppColors.textPrimary, size: 15))),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(46, 204, 113, 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.robot,
                        color: AppColors.neonGreen, size: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'Manager ',
                          style: GoogleFonts.montserrat(
                              color: AppColors.textPrimary, fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      TextSpan(text: 'AI',
                          style: GoogleFonts.montserrat(
                              color: AppColors.neonGreen, fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ])),
                    Text('Delegate scheduling & admin tasks',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                )),
                if (_messages.isNotEmpty)
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _messages.clear()),
                      child: const SizedBox(width: 40, height: 40,
                        child: Center(child: FaIcon(
                            FontAwesomeIcons.trashCan,
                            color: AppColors.textSecondary, size: 14))),
                    ),
                  ),
              ]),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── Messages ─────────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? _ManagerWelcome(
                      suggestions: _suggestions,
                      onSuggestion: (s) => _send(s))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:    EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                      itemCount:  _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_loading && i == _messages.length) {
                          return _buildTyping();
                        }
                        return _buildBubble(_messages[i]);
                      },
                    ),
            ),

            // ── Input ────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
              decoration: const BoxDecoration(
                color:  AppColors.background,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      minLines:   1,
                      maxLines:   5,
                      enabled:    !_loading,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Give me a task…',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _loading ? AppColors.surface : AppColors.neonGreen,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _loading ? null : _send,
                    child: SizedBox(width: 44, height: 44,
                      child: _loading
                          ? const Center(child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.neonGreen)))
                          : const Center(child: FaIcon(
                              FontAwesomeIcons.arrowUp,
                              color: Colors.black, size: 16))),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(AiChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        const Color.fromRGBO(46, 204, 113, 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.4)),
              ),
              child: const Center(child: FaIcon(FontAwesomeIcons.robot,
                  color: AppColors.neonGreen, size: 11)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color.fromRGBO(46, 204, 113, 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? Border.all(
                          color: const Color.fromRGBO(46, 204, 113, 0.3))
                      : Border.all(color: AppColors.divider),
                ),
                child: Text(msg.content,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14,
                        height: 1.45)),
              ),
              // Actions summary
              if (msg.actions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 4,
                    children: msg.actions.map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        const Color.fromRGBO(46, 204, 113, 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color.fromRGBO(46, 204, 113, 0.25)),
                      ),
                      child: Text(_actionLabel(a.tool),
                          style: GoogleFonts.inter(
                              color: AppColors.neonGreen, fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    )).toList()),
              ],
              const SizedBox(height: 3),
              Text(_fmt(msg.timestamp),
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          )),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildTyping() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:        const Color.fromRGBO(46, 204, 113, 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.4)),
            ),
            child: const Center(child: FaIcon(FontAwesomeIcons.robot,
                color: AppColors.neonGreen, size: 11)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
              border: Border.all(color: AppColors.divider),
            ),
            child: const SizedBox(
              width: 40, height: 14,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                _Dot(delay: 0),
                _Dot(delay: 200),
                _Dot(delay: 400),
              ]),
            ),
          ),
        ]),
      );

  static String _actionLabel(String tool) => switch (tool) {
        'createWeekAgenda'   => '✓ Created agenda',
        'publishAgenda'      => '✓ Published',
        'deleteAgenda'       => '✗ Deleted agenda',
        'setDayPlanType'     => '✓ Updated day plan',
        'deleteTimeSlot'     => '✗ Deleted slot',
        'createTimeSlot'     => '✓ Created slot',
        'confirmReservation' => '✓ Confirmed reservation',
        'getPendingReservations' => '⟳ Checked reservations',
        'getMyTerrains'      => '⟳ Fetched terrains',
        'getAgendaDetails'   => '⟳ Read agenda',
        _                    => '⟳ ${tool.replaceAllMapped(
              RegExp(r'[A-Z]'), (m) => ' ${m[0]}').trim()}',
      };

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Pulsing dot for typing indicator ────────────────────────────────────────

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    // Stagger by delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            color: AppColors.neonGreen, shape: BoxShape.circle),
        ),
      );
}

// ─── Manager welcome / suggestion screen ─────────────────────────────────────

class _ManagerWelcome extends StatelessWidget {
  const _ManagerWelcome({
    required this.suggestions,
    required this.onSuggestion,
  });
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:        const Color.fromRGBO(46, 204, 113, 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.5)),
              ),
              child: const Center(child: FaIcon(FontAwesomeIcons.robot,
                  color: AppColors.neonGreen, size: 28)),
            ),
            const SizedBox(height: 16),
            RichText(text: TextSpan(children: [
              TextSpan(text: 'Manager ',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary, fontSize: 22,
                      fontWeight: FontWeight.w800)),
              TextSpan(text: 'AI',
                  style: GoogleFonts.montserrat(
                      color: AppColors.neonGreen, fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ])),
            const SizedBox(height: 6),
            Text(
              'Delegate complex scheduling tasks.\n'
              'The AI will plan, create, and publish on your behalf.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13,
                  height: 1.5),
            ),
          ])),
          const SizedBox(height: 32),
          Text('Example tasks',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 10),
          ...suggestions.map((s) => GestureDetector(
                onTap: () => onSuggestion(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color.fromRGBO(46, 204, 113, 0.25)),
                  ),
                  child: Row(children: [
                    const FaIcon(FontAwesomeIcons.wandMagicSparkles,
                        color: AppColors.neonGreen, size: 12),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 13))),
                    const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare,
                        color: AppColors.textSecondary, size: 11),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

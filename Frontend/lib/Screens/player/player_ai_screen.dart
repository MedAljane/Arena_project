import 'dart:math';
import 'package:Arena/models/ai/ai_chat.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerAiScreen extends StatefulWidget {
  const PlayerAiScreen({super.key});

  @override
  State<PlayerAiScreen> createState() => _PlayerAiScreenState();
}

class _PlayerAiScreenState extends State<PlayerAiScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _loading = false;

  // Groups all turns in this screen session for analytics.
  final String _sessionId = _genId();

  static const _suggestions = [
    'Find me a Football slot this Saturday afternoon',
    'Book a Basketball court next Monday between 6PM and 9PM',
    'What are my upcoming reservations?',
    'Cancel my latest reservation',
  ];

  static String _genId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

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
    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final svc = context.read<AiService>();
      // Only send the last 20 turns to keep context manageable
      final history = _messages
          .where((m) => m.role != 'user' || m != userMsg)
          .take(40)
          .toList();
      final response = await svc.playerChat(msg, history, _sessionId);

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
      setState(() { _loading = false; });
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
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
      behavior:        SnackBarBehavior.floating,
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
              child: Row(
                children: [
                  Material(
                    color:        AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap:        () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40, height: 40,
                        child: Center(child: FaIcon(
                            FontAwesomeIcons.arrowLeft,
                            color: AppColors.textPrimary, size: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF011647), Color(0xFF26314D)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.5)),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.bolt,
                          color: AppColors.neonGreen, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(text: 'Arena ',
                                style: GoogleFonts.montserrat(
                                    color:      AppColors.textPrimary,
                                    fontSize:   15,
                                    fontWeight: FontWeight.w800)),
                            TextSpan(text: 'AI',
                                style: GoogleFonts.montserrat(
                                    color:      AppColors.neonGreen,
                                    fontSize:   15,
                                    fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        Text('Your intelligent sports companion',
                            style: GoogleFonts.inter(
                                color:    AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  // Clear history
                  if (_messages.isNotEmpty)
                    Material(
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _messages.clear()),
                        child: const SizedBox(
                          width: 40, height: 40,
                          child: Center(child: FaIcon(
                              FontAwesomeIcons.trashCan,
                              color: AppColors.textSecondary, size: 14)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 20),

            // ── Messages ─────────────────────────────────────────────
            Expanded(
              child: _messages.isEmpty
                  ? _WelcomeView(
                      suggestions: _suggestions,
                      onSuggestion: (s) => _send(s),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics:    const AlwaysScrollableScrollPhysics(),
                      padding:    EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                      itemCount:  _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_loading && i == _messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(msg: _messages[i]);
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
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border:       Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        minLines:   1,
                        maxLines:   4,
                        enabled:    !_loading,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText:  'Ask me anything…',
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
                    color:  _loading
                        ? AppColors.surface
                        : AppColors.neonGreen,
                    shape:  const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _loading ? null : _send,
                      child: SizedBox(
                        width: 44, height: 44,
                        child: _loading
                            ? const Center(child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonGreen)))
                            : const Center(child: FaIcon(
                                FontAwesomeIcons.arrowUp,
                                color: Colors.black, size: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome / empty state ────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.suggestions,
    required this.onSuggestion,
  });
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.052,
            vertical:   24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF011647), Color(0xFF26314D)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: FaIcon(FontAwesomeIcons.bolt,
                        color: AppColors.neonGreen, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'Arena ',
                      style: GoogleFonts.montserrat(
                          color:      AppColors.textPrimary,
                          fontSize:   22,
                          fontWeight: FontWeight.w800)),
                  TextSpan(text: 'AI',
                      style: GoogleFonts.montserrat(
                          color:      AppColors.neonGreen,
                          fontSize:   22,
                          fontWeight: FontWeight.w800)),
                ])),
                const SizedBox(height: 6),
                Text('Tell me what you want to play and when.\nI\'ll find and book the slot for you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13,
                        height: 1.5)),
              ]),
            ),
            const SizedBox(height: 32),
            Text('Try asking',
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
                      color:        AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color.fromRGBO(46, 204, 113, 0.25)),
                    ),
                    child: Row(children: [
                      const FaIcon(FontAwesomeIcons.magnifyingGlass,
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

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final AiChatMessage msg;

  @override
  Widget build(BuildContext context) {
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF011647), Color(0xFF26314D)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.bolt,
                    color: AppColors.neonGreen, size: 11),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
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
                // Actions taken by the AI
                if (msg.actions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4,
                      children: msg.actions.map((a) => _ActionChip(a)).toList()),
                ],
                const SizedBox(height: 3),
                Text(_fmt(msg.timestamp),
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Action chip shown under AI messages ─────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.action);
  final AiAction action;

  static String _label(String tool) => switch (tool) {
        'bookReservation'      => '✓ Booked',
        'cancelReservation'    => '✗ Cancelled',
        'getAvailableSlots'    => '⟳ Searched slots',
        'getAvailableSlotsForDate' => '⟳ Searched slots',
        'getCampusesAndTerrains'   => '⟳ Fetched campuses',
        'getMyReservations'    => '⟳ Checked bookings',
        _                      => '⟳ ${tool.replaceAllMapped(
              RegExp(r'[A-Z]'),
              (m) => ' ${m[0]}',
            ).trim()}',
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color:        const Color.fromRGBO(46, 204, 113, 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color.fromRGBO(46, 204, 113, 0.25)),
        ),
        child: Text(_label(action.tool),
            style: GoogleFonts.inter(
                color:      AppColors.neonGreen,
                fontSize:   10,
                fontWeight: FontWeight.w600)),
      );
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF011647), Color(0xFF26314D)]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.bolt,
                    color: AppColors.neonGreen, size: 11)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:        AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(18),
                  topRight:    Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft:  Radius.circular(4),
                ),
                border: Border.all(color: AppColors.divider),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final opacity = (((_ctrl.value * 3 - i).clamp(0, 1)) *
                            (1 - ((_ctrl.value * 3 - i - 1).clamp(0, 1))))
                        .toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: 0.3 + 0.7 * opacity,
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color:  AppColors.neonGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
}

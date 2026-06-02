import 'package:Arena/models/models.dart';
import 'package:Arena/providers/auth_provider.dart';
import 'package:Arena/services/chat/chat_service.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending     = false;
  late String _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = context.read<AuthProvider>().authUser!.id.toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      // Write goes through the backend REST API → Admin SDK → Firestore.
      // The Firestore stream listener below picks up the new doc automatically.
      await context.read<MessageService>().sendMessage(SendMessageRequest(
        conversationId: widget.conversationId,
        senderUid:      _myUid,
        text:           text,
      ));
    } on ServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
              child: Row(
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40, height: 40,
                        child: Center(child: FaIcon(FontAwesomeIcons.arrowLeft,
                            color: AppColors.textPrimary, size: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color.fromRGBO(46, 204, 113, 0.15),
                    child: Text(
                      widget.title.isNotEmpty
                          ? widget.title[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.montserrat(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: GoogleFonts.montserrat(
                                color: AppColors.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            Container(
                              width: 7, height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.neonGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('Live',
                                style: GoogleFonts.inter(
                                    color: AppColors.neonGreen, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, height: 16, thickness: 1),

            // ── Real-time message list ────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: ChatService.streamMessages(widget.conversationId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonGreen));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary)),
                    );
                  }
                  final messages = snap.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const FaIcon(FontAwesomeIcons.message,
                            color: AppColors.textSecondary, size: 40),
                        const SizedBox(height: 14),
                        Text('No messages yet. Say hello!',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 14)),
                      ]),
                    );
                  }
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                      message: messages[i],
                      isMe:    messages[i].senderUid == _myUid,
                    ),
                  );
                },
              ),
            ),

            // ── Input bar ────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        minLines: 1,
                        maxLines: 4,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message…',
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
                    color: _sending
                        ? AppColors.surface
                        : AppColors.neonGreen,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: SizedBox(
                        width: 44, height: 44,
                        child: _sending
                            ? const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.neonGreen),
                                ))
                            : const Center(
                                child: FaIcon(FontAwesomeIcons.paperPlane,
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

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final Message message;
  final bool isMe;

  String _fmtTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color.fromRGBO(46, 204, 113, 0.15),
                child: Text(
                  message.senderUid.isNotEmpty
                      ? message.senderUid[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.montserrat(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color.fromRGBO(46, 204, 113, 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft:     const Radius.circular(18),
                        topRight:    const Radius.circular(18),
                        bottomLeft:  Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: isMe
                          ? Border.all(
                              color: const Color.fromRGBO(46, 204, 113, 0.3))
                          : Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      message.text,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtTime(message.createdAt),
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 6),
          ],
        ),
      );
}

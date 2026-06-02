import 'package:Arena/Screens/shared/conversation_screen.dart';
import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/chat/chat_service.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerChatScreen extends StatefulWidget {
  const PlayerChatScreen({super.key});

  @override
  State<PlayerChatScreen> createState() => _PlayerChatScreenState();
}

class _PlayerChatScreenState extends State<PlayerChatScreen> {
  // Used only for employees: holds their profile ID once loaded.
  int?   _employeeProfileId;
  bool   _employeeProfileLoading = false;

  @override
  void initState() {
    super.initState();
    final role = context.read<AuthProvider>().role;
    if (role == UserRole.employee) {
      _loadEmployeeProfileId();
    } else {
      // Player — load full profile + reservations for rich tile labels.
      context.read<PlayerProvider>().load(context.read<PlayerService>());
      context.read<ReservationProvider>().load(context.read<ReservationService>());
    }
  }

  Future<void> _loadEmployeeProfileId() async {
    setState(() => _employeeProfileLoading = true);
    final id = await context.read<EmployeeService>().getMyProfileId();
    if (mounted) setState(() { _employeeProfileId = id; _employeeProfileLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final role       = context.watch<AuthProvider>().role;
    final playerProv = context.watch<PlayerProvider>();
    final resProv    = context.watch<ReservationProvider>();
    final hPad       = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Text('Messages',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: () {
                // ── Employee branch ──────────────────────────────────────
                if (role == UserRole.employee) {
                  if (_employeeProfileLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonGreen));
                  }
                  final empId = _employeeProfileId;
                  if (empId == null) {
                    return Center(
                      child: Text('Employee profile not found.',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14)),
                    );
                  }
                  return _ConversationStream(
                    stream:  ChatService.streamEmployeeConversations(empId.toString()),
                    hPad:    hPad,
                    resProv: resProv,
                    emptyHint: 'Conversations with players will appear\nafter a reservation is confirmed.',
                  );
                }

                // ── Player branch ────────────────────────────────────────
                if (playerProv.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonGreen));
                }
                final profileId = playerProv.profile?.id;
                if (profileId == null) {
                  return Center(
                    child: Text('Profile not found.',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 14)),
                  );
                }

                return _ConversationStream(
                  stream:  ChatService.streamPlayerConversations(profileId.toString()),
                  hPad:    hPad,
                  resProv: resProv,
                  emptyHint: 'Book a terrain and a chat with\nArena Support will appear here.',
                );
              }(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared stream widget ─────────────────────────────────────────────────────

class _ConversationStream extends StatelessWidget {
  const _ConversationStream({
    required this.stream,
    required this.hPad,
    required this.resProv,
    required this.emptyHint,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final double              hPad;
  final ReservationProvider resProv;
  final String              emptyHint;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Error: ${snap.error}',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const FaIcon(FontAwesomeIcons.message,
                  color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 14),
              Text('No conversations yet.',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 6),
              Text(emptyHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
            ]),
          );
        }

        final sorted = docs.toList()
          ..sort((a, b) {
            final aTs   = a.data()['lastMessageAt'];
            final bTs   = b.data()['lastMessageAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.now();
            final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.now();
            return bDate.compareTo(aDate);
          });

        return RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: () async => resProv.refresh(context.read<ReservationService>()),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final doc     = sorted[i];
              final data    = doc.data();
              final resId   = int.tryParse(data['reservationId']?.toString() ?? '');
              final reservation = resId != null
                  ? resProv.reservations.where((r) => r.id == resId).firstOrNull
                  : null;
              return _ReservationConversationTile(
                doc:         doc,
                reservation: reservation,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      conversationId: doc.id,
                      title:          'Arena Support',
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Reservation conversation tile ────────────────────────────────────────────

class _ReservationConversationTile extends StatelessWidget {
  const _ReservationConversationTile({
    required this.doc,
    required this.onTap,
    this.reservation,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Reservation? reservation;
  final VoidCallback onTap;

  static dynamic _iconFor(dynamic type) {
    if (type == null) return FontAwesomeIcons.trophy;
    final name = type.toString().toLowerCase();
    if (name.contains('football'))   return FontAwesomeIcons.futbol;
    if (name.contains('basketball')) return FontAwesomeIcons.basketball;
    if (name.contains('paddel') || name.contains('tennis')) {
      return FontAwesomeIcons.tableTennisPaddleBall;
    }
    return FontAwesomeIcons.trophy;
  }

  @override
  Widget build(BuildContext context) {
    final data      = doc.data();
    final lastMsg   = data['lastMessage'] as String? ?? 'Tap to open chat';
    final lastMsgAt = data['lastMessageAt'];
    final timeLabel = _fmtTime(lastMsgAt);

    // Title: terrain type + slot time if reservation is known
    String title = 'Arena Support';
    dynamic icon = FontAwesomeIcons.trophy;

    final terrain = reservation?.terrain;
    if (terrain != null) {
      title = '${terrain.type.name} Booking';
      icon  = _iconFor(terrain.type.name);
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(46, 204, 113, 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FaIcon(icon,
                          color: AppColors.neonGreen, size: 18),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(timeLabel,
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const FaIcon(FontAwesomeIcons.chevronRight,
                  color: AppColors.textSecondary, size: 11),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate().toLocal();
    } else if (value is String) {
      dt = DateTime.tryParse(value)?.toLocal();
    }
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}

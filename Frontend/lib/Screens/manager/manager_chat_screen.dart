import 'package:Arena/models/models.dart';
import 'package:Arena/Screens/shared/conversation_screen.dart';
import 'package:Arena/services/chat/chat_service.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ManagerChatScreen extends StatefulWidget {
  const ManagerChatScreen({super.key});

  @override
  State<ManagerChatScreen> createState() => _ManagerChatScreenState();
}

class _ManagerChatScreenState extends State<ManagerChatScreen> {
  List<Employee> _employees = [];
  List<Employee> _filtered  = [];
  bool    _loading = true;
  String? _error;
  final   _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<EmployeeService>().getManagerEmployees();
      if (mounted) setState(() { _employees = list; _filtered = list; _loading = false; });
    } on ServiceException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _employees
          : _employees
              .where((e) => e.username.toLowerCase().contains(q))
              .toList();
    });
  }

  void _openConversation(Employee emp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: emp.id.toString(),
          title:          emp.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
              child: Text('Messages',
                  style: GoogleFonts.montserrat(
                      color: AppColors.textPrimary,
                      fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),

            // ── Search ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const FaIcon(FontAwesomeIcons.magnifyingGlass,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search employees…',
                          hintStyle: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Employee list ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonGreen))
                  : _error != null
                      ? Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(_error!,
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _fetch,
                              child: Text('Retry',
                                  style: GoogleFonts.inter(
                                      color: AppColors.neonGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ]))
                      : _filtered.isEmpty
                          ? Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                const FaIcon(FontAwesomeIcons.message,
                                    color: AppColors.textSecondary,
                                    size: 40),
                                const SizedBox(height: 14),
                                Text('No employees found.',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                              ]))
                          : RefreshIndicator(
                              color: AppColors.neonGreen,
                              onRefresh: _fetch,
                              child: ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                    hPad, 0, hPad, 40),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) => _ContactTile(
                                  employee:       _filtered[i],
                                  conversationId: _filtered[i].id.toString(),
                                  onTap: () => _openConversation(_filtered[i]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Employee contact tile with live last-message preview ─────────────────────

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.employee,
    required this.conversationId,
    required this.onTap,
  });

  final Employee     employee;
  final String       conversationId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ChatService.streamConversation(conversationId),
      builder: (context, snap) {
        final data      = snap.data?.data();
        final lastMsg   = data?['lastMessage'] as String? ?? employee.email;
        final lastMsgAt = data?['lastMessageAt'];
        final timeLabel = _fmtTime(lastMsgAt);

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        const Color.fromRGBO(46, 204, 113, 0.12),
                    child: Text(
                      employee.username.isNotEmpty
                          ? employee.username[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.montserrat(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(employee.username,
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
      },
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
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}

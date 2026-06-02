import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:Arena/widgets/ai_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerDashboardScreen extends StatefulWidget {
  const PlayerDashboardScreen({super.key});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  int _selectedCategory = 0;
  static const _categories = ['Football', 'Padel', 'Basketball', 'Tennis'];

  @override
  void initState() {
    super.initState();
    // Load via providers — data is shared with other screens and only fetched once.
    final campusSvc      = context.read<CampusService>();
    final reservationSvc = context.read<ReservationService>();
    context.read<CampusProvider>().loadAll(campusSvc);
    context.read<ReservationProvider>().load(reservationSvc);
  }

  @override
  Widget build(BuildContext context) {
    final user        = context.watch<AuthProvider>();
    final campuses    = context.watch<CampusProvider>();
    final reservations = context.watch<ReservationProvider>();
    final hPad        = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: () async {
            final campusSvc      = context.read<CampusService>();
            final reservationSvc = context.read<ReservationService>();
            await Future.wait([
              context.read<CampusProvider>().refreshAll(campusSvc),
              context.read<ReservationProvider>().refresh(reservationSvc),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _Header(user: user),
              const SizedBox(height: 26),
              const AiHeroCard(),
              const SizedBox(height: 26),
              const _SectionLabel('Sport Categories'),
              const SizedBox(height: 12),
              _CategoryChips(
                categories: _categories,
                selectedIndex: _selectedCategory,
                onTap: (i) => setState(() => _selectedCategory = i),
              ),
              const SizedBox(height: 26),
              const _SectionLabel('Upcoming Booking'),
              const SizedBox(height: 12),
              if (reservations.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
              else if (reservations.nextUpcoming != null)
                _UpcomingReservationCard(reservation: reservations.nextUpcoming!)
              else
                _EmptyBookingCard(),
              const SizedBox(height: 26),
              const _SectionLabel('Nearby Campuses'),
              const SizedBox(height: 12),
              if (campuses.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
              else if (campuses.campuses.isEmpty)
                Center(
                  child: Text('No campuses found',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                )
              else
                _CampusRow(campuses: campuses.campuses),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AuthProvider user;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color.fromRGBO(46, 204, 113, 0.12),
            child: Text(user.avatarInitials,
                style: GoogleFonts.montserrat(color: AppColors.neonGreen, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Game! 👋',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.5)),
                Text('Hello, ${user.name}',
                    style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.read<AuthProvider>().markNotificationsRead(),
                  child: const SizedBox(
                    width: 46, height: 46,
                    child: Center(child: FaIcon(FontAwesomeIcons.bell, color: AppColors.textPrimary, size: 18)),
                  ),
                ),
              ),
              if (user.notificationCount > 0)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${user.notificationCount}',
                          style: GoogleFonts.inter(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.montserrat(
          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2));
}

// ─── Category chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories, required this.selectedIndex, required this.onTap});
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static final _iconMap = <String, dynamic>{
    'Football':   FontAwesomeIcons.futbol,
    'Padel':      FontAwesomeIcons.tableTennisPaddleBall,
    'Basketball': FontAwesomeIcons.basketball,
    'Tennis':     FontAwesomeIcons.tableTennisPaddleBall,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final active = i == selectedIndex;
            final label = categories[i];
            final icon = _iconMap[label] ?? FontAwesomeIcons.circleCheck;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active ? AppColors.neonGreen : AppColors.chipInactiveBg,
                  borderRadius: BorderRadius.circular(24),
                  border: active ? null : Border.all(color: AppColors.chipInactiveBorder),
                ),
                child: Row(
                  children: [
                    FaIcon(icon, color: active ? Colors.black : AppColors.textSecondary, size: 13),
                    const SizedBox(width: 7),
                    Text(label,
                        style: GoogleFonts.inter(
                            color: active ? Colors.black : AppColors.textSecondary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

// ─── Upcoming reservation card ────────────────────────────────────────────────

class _UpcomingReservationCard extends StatelessWidget {
  const _UpcomingReservationCard({required this.reservation});
  final Reservation reservation;

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sport = reservation.terrain?.type.name ?? 'Booking';
    final timeSlot = reservation.timeSlot;
    final timeLabel = timeSlot != null ? '${timeSlot.startTime} – ${timeSlot.endTime}' : '—';
    final isPending = reservation.statu == ReservationStatus.pending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPending
            ? const Color.fromRGBO(255, 193, 7, 0.5)
            : const Color.fromRGBO(46, 204, 113, 0.4)),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color.fromRGBO(255, 193, 7, 0.15)
                : const Color.fromRGBO(46, 204, 113, 0.20),
            blurRadius: 20, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.futbol, color: AppColors.neonGreen, size: 14),
              const SizedBox(width: 7),
              Text(sport.toUpperCase(),
                  style: GoogleFonts.montserrat(
                      color: AppColors.neonGreen, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.6)),
              const Spacer(),
              _StatusBadge(statu: reservation.statu),
            ],
          ),
          const SizedBox(height: 8),
          Text('Terrain #${reservation.terrain?.id ?? '—'}',
              style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoPill(icon: FontAwesomeIcons.calendarDay, label: _fmtDate(reservation.bookedAt)),
              const SizedBox(width: 18),
              _InfoPill(icon: FontAwesomeIcons.clock, label: timeLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.statu});
  final ReservationStatus statu;

  Color get _color => switch (statu) {
        ReservationStatus.confirmed => AppColors.neonGreen,
        ReservationStatus.pending   => const Color(0xFFFFC107),
        ReservationStatus.cancelled => Colors.redAccent,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Text(
          statu.name[0].toUpperCase() + statu.name.substring(1),
          style: GoogleFonts.inter(color: _color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
        ),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final dynamic icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: AppColors.textSecondary, size: 12),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      );
}

class _EmptyBookingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.calendarXmark, color: AppColors.textSecondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No upcoming bookings',
                      style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Browse campuses and book a slot.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Campus row ───────────────────────────────────────────────────────────────

class _CampusRow extends StatelessWidget {
  const _CampusRow({required this.campuses});
  final List<Campus> campuses;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 205,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: campuses.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, i) => _CampusCard(campus: campuses[i]),
        ),
      );
}

class _CampusCard extends StatelessWidget {
  const _CampusCard({required this.campus});
  final Campus campus;

  @override
  Widget build(BuildContext context) {
    final imageUrl = campus.mainImage?.fullUrl
        ?? 'https://picsum.photos/seed/${campus.id}/400/230';

    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0,0,0,0.25), blurRadius: 10, offset: Offset(0,4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 115,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen))),
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(child: FaIcon(FontAwesomeIcons.building, color: Color.fromRGBO(255,255,255,0.2), size: 36)),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color.fromRGBO(0,0,0,0.65),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.trophy, color: AppColors.neonGreen, size: 9),
                        const SizedBox(width: 4),
                        Text('${campus.nbTerrains}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campus.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(campus.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

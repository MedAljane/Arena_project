import 'package:Arena/Screens/player/player_ai_screen.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AiHeroCard extends StatelessWidget {
  const AiHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromRGBO(1, 22, 71, 1), Color.fromRGBO(38, 49, 77, 1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branding Row ─────────────────────────────────────────────────
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.bolt,
                color: AppColors.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Arena ',
                      style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'AI',
                      style: GoogleFonts.montserrat(
                        color: AppColors.neonGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your intelligent sports companion',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // ── Natural-Language Search Bar ───────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlayerAiScreen())),
            child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color.fromRGBO(46, 204, 113, 0.30),
              ),
            ),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Find a court, ask anything...',
                    style: GoogleFonts.inter(
                      color: const Color.fromRGBO(158, 158, 158, 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.arrowUp,
                      color: Colors.black,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),   // GestureDetector
        ],
      ),
    );
  }
}
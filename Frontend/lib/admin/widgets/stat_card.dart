import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.route,
    this.loading = false,
  });

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final String?  route;
  final bool     loading;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return InkWell(
      onTap:        route != null ? () => context.go(route!) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        ext.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: ext.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width:  36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (route != null)
                  Icon(Icons.arrow_forward, size: 13, color: ext.subtle),
              ],
            ),
            const SizedBox(height: 10),
            loading
                ? Container(
                    width: 52, height: 26,
                    decoration: BoxDecoration(
                      color:        ext.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                        color:      ext.text,
                        fontSize:   24,
                        fontWeight: FontWeight.w800),
                  ),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ext.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

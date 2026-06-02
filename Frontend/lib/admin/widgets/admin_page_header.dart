import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAdd,
    this.addLabel,
    this.badge,
  });

  final String       title;
  final String       subtitle;
  final VoidCallback? onAdd;
  final String?      addLabel;
  /// Optional right-aligned read-only badge (used on read-only pages).
  final String?      badge;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color:      ext.text,
                      fontSize:   22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(color: ext.muted, fontSize: 13)),
            ],
          ),
        ),
        if (onAdd != null)
          ElevatedButton.icon(
            onPressed: onAdd,
            icon:  const Icon(Icons.add, size: 16, color: Colors.white),
            label: Text(addLabel ?? 'New',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color:        ext.card,
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: ext.border),
            ),
            child: Text(badge!,
                style: TextStyle(color: ext.subtle, fontSize: 12)),
          ),
      ],
    );
  }
}

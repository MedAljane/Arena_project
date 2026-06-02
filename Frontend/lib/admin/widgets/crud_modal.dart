import 'package:Arena/admin/theme/admin_colors.dart';
import 'package:Arena/admin/theme/admin_theme.dart';
import 'package:flutter/material.dart';

/// Generic create / edit / delete modal for admin CRUD screens.
class CrudModal extends StatelessWidget {
  const CrudModal({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String   title;
  final VoidCallback onClose;
  final Widget   child;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color:        ext.card,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: ext.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ext.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            color:      ext.text,
                            fontSize:   17,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed:   onClose,
                    icon:        Icon(Icons.close, color: ext.muted, size: 20),
                    padding:     EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child:   child,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete confirmation modal ────────────────────────────────────────────────

class DeleteModal extends StatelessWidget {
  const DeleteModal({
    super.key,
    required this.title,
    required this.description,
    required this.onConfirm,
    required this.onCancel,
    this.deleting = false,
  });

  final String   title;
  final String   description;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool     deleting;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;

    return CrudModal(
      title:   title,
      onClose: onCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(description,
              style: TextStyle(color: ext.muted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side:  BorderSide(color: ext.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(color: ext.muted, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: deleting ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.danger,
                    disabledBackgroundColor:
                        AdminColors.danger.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(deleting ? 'Deleting…' : 'Delete',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared form field ────────────────────────────────────────────────────────

class ModalField extends StatelessWidget {
  const ModalField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.type   = TextInputType.text,
    this.obscure = false,
    this.optional = false,
  });

  final String               label;
  final TextEditingController controller;
  final String?              hint;
  final TextInputType        type;
  final bool                 obscure;
  final bool                 optional;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    color:      ext.muted,
                    fontSize:   13,
                    fontWeight: FontWeight.w500)),
            if (optional)
              Text(' (optional)',
                  style:
                      TextStyle(color: ext.subtle, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller:   controller,
          keyboardType: type,
          obscureText:  obscure,
          style:        TextStyle(color: ext.text, fontSize: 14),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: TextStyle(color: ext.subtle, fontSize: 14),
            filled:    true,
            fillColor: ext.input,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide: const BorderSide(
                  color: AdminColors.indigo, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class ModalErrorBanner extends StatelessWidget {
  const ModalErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:  AdminColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AdminColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AdminColors.danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AdminColors.danger, fontSize: 13)),
            ),
          ],
        ),
      );
}

// ─── Save / Cancel row ────────────────────────────────────────────────────────

class ModalActions extends StatelessWidget {
  const ModalActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saving   = false,
    this.saveLabel = 'Save',
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool   saving;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final ext = context.adminExt;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side:    BorderSide(color: ext.border),
              shape:   RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Cancel',
                style: TextStyle(color: ext.muted, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.indigo,
              disabledBackgroundColor:
                  AdminColors.indigo.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:   const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: Text(saving ? 'Saving…' : saveLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

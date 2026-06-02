import 'package:Arena/models/models.dart';
import 'package:Arena/providers/providers.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlayerPersonalInfoScreen extends StatefulWidget {
  const PlayerPersonalInfoScreen({super.key});

  @override
  State<PlayerPersonalInfoScreen> createState() => _PlayerPersonalInfoScreenState();
}

class _PlayerPersonalInfoScreenState extends State<PlayerPersonalInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth   = context.read<AuthProvider>();
    final player = context.read<PlayerProvider>();

    // Prefer the backend-loaded profile; fall back to AuthProvider display values.
    _nameCtrl     = TextEditingController(text: player.nom     ?? auth.name);
    _emailCtrl    = TextEditingController(text: player.profile?.user?.email ?? auth.email);
    _phoneCtrl    = TextEditingController(text: player.phone   ?? auth.phone);
    _locationCtrl = TextEditingController(text: player.address ?? auth.location);

    // Ensure the full profile is loaded so future opens pre-fill correctly.
    context.read<PlayerProvider>().load(context.read<PlayerService>());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final phone   = _phoneCtrl.text.trim();
    final address = _locationCtrl.text.trim();

    setState(() => _saving = true);
    try {
      await context.read<PlayerProvider>().updateProfile(
        context.read<PlayerService>(),
        UpdatePlayerRequest(
          username: name.isEmpty    ? null : name,
          email:    email.isEmpty   ? null : email,
          phone:    phone.isEmpty   ? null : phone,
          address:  address.isEmpty ? null : address,
        ),
      );
      if (!mounted) return;

      // Keep the in-memory display name and local prefs in sync.
      context.read<AuthProvider>().updateProfile(
        name:     name,
        phone:    phone,
        location: address,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text('Info updated!',
            style: GoogleFonts.inter(
                color: Colors.black, fontWeight: FontWeight.w700)),
      ));
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(e.message,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width * 0.052;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Personal Info',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  _saving
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: AppColors.neonGreen, strokeWidth: 2))
                      : Material(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _save,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              child: Text('Save',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  children: [
                    _InfoField(label: 'Full Name',     icon: FontAwesomeIcons.user,        controller: _nameCtrl),
                    const SizedBox(height: 14),
                    _InfoField(label: 'Email Address', icon: FontAwesomeIcons.envelope,    controller: _emailCtrl,  keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _InfoField(
                      label: 'Phone', icon: FontAwesomeIcons.phone, controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]'))],
                    ),
                    const SizedBox(height: 14),
                    _InfoField(label: 'Location', icon: FontAwesomeIcons.locationDot, controller: _locationCtrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });
  final String label;
  final dynamic icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(46, 204, 113, 0.35)),
            ),
            child: TextField(
              controller:       controller,
              keyboardType:     keyboardType,
              inputFormatters:  inputFormatters,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(widthFactor: 1,
                      child: FaIcon(icon, color: AppColors.neonGreen, size: 14)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0, vertical: 14),
              ),
            ),
          ),
        ],
      );
}

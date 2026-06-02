import 'dart:io';

import 'package:Arena/models/models.dart';
import 'package:Arena/services/services.dart';
import 'package:Arena/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateCampusScreen extends StatefulWidget {
  const CreateCampusScreen({super.key});

  @override
  State<CreateCampusScreen> createState() => _CreateCampusScreenState();
}

class _CreateCampusScreenState extends State<CreateCampusScreen> {
  final _nameCtrl       = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _nbTerrainsCtrl = TextEditingController(text: '1');
  final _picker         = ImagePicker();

  XFile?       _mainImage;
  List<XFile>  _galleryImages = [];
  bool         _loading       = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _nbTerrainsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _mainImage = file);
  }

  Future<void> _pickGalleryImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _galleryImages = [..._galleryImages, ...files]);
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryImages.removeAt(index));
  }

  Future<void> _submit() async {
    final name    = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final nb      = int.tryParse(_nbTerrainsCtrl.text.trim()) ?? 0;

    if (name.isEmpty) {
      _msg('Campus name is required.', isError: true);
      return;
    }
    if (address.isEmpty) {
      _msg('Address is required.', isError: true);
      return;
    }
    if (nb < 1) {
      _msg('Number of terrains must be at least 1.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final service = context.read<CampusService>();

      int? mainImageId;
      List<int> galleryIds = [];

      if (_mainImage != null) {
        final ids = await service.uploadFiles([_mainImage!]);
        mainImageId = ids.first;
      }
      if (_galleryImages.isNotEmpty) {
        galleryIds = await service.uploadFiles(_galleryImages);
      }

      await service.createCampus(
        CampusRequest(
          name:        name,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          address:     address,
          phone:       _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          nbTerrains:  nb,
          mainImageId: mainImageId,
          galleryIds:  galleryIds,
        ),
      );
      if (!mounted) return;
      _msg('Campus created!');
      Navigator.pop(context, true);
    } on ServiceException catch (e) {
      _msg(e.message, isError: true);
    } catch (e) {
      _msg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text,
          style: GoogleFonts.inter(
              color: isError ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.redAccent : AppColors.neonGreen,
      behavior: SnackBarBehavior.floating,
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
            // ── Top bar ────────────────────────────────────────────────
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
                    child: Text('New Campus',
                        style: GoogleFonts.montserrat(
                            color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Form ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(label: 'Campus Name *',  controller: _nameCtrl,    hint: 'e.g. Arena Nord'),
                    const SizedBox(height: 14),
                    _Field(label: 'Address *',       controller: _addressCtrl, hint: 'Street, City, Country'),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text('Address is auto-geocoded to coordinates.',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Number of Terrains *',
                      controller: _nbTerrainsCtrl,
                      hint: '1',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 14),
                    _Field(label: 'Phone',        controller: _phoneCtrl, hint: 'Optional',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _Field(label: 'Description',  controller: _descCtrl,  hint: 'Optional',
                        maxLines: 3),
                    const SizedBox(height: 20),

                    // ── Main Image ────────────────────────────────────
                    _sectionLabel('Main Image'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickMainImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color.fromRGBO(46, 204, 113, 0.35)),
                        ),
                        child: _mainImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(FontAwesomeIcons.image,
                                      color: AppColors.textSecondary, size: 28),
                                  const SizedBox(height: 8),
                                  Text('Tap to select main image',
                                      style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                          fontSize: 13)),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_mainImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _mainImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const FaIcon(FontAwesomeIcons.xmark,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Gallery ───────────────────────────────────────
                    _sectionLabel('Gallery'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._galleryImages.asMap().entries.map((entry) {
                            final i    = entry.key;
                            final file = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(file.path),
                                      width: 90, height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeGalleryImage(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const FaIcon(FontAwesomeIcons.xmark,
                                            color: Colors.white, size: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _pickGalleryImages,
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color.fromRGBO(46, 204, 113, 0.35)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.plus,
                                      color: AppColors.neonGreen, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit ────────────────────────────────────────
                    _loading
                        ? const Center(child: CircularProgressIndicator(
                              color: AppColors.neonGreen))
                        : SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.neonGreen,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _submit,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('CREATE CAMPUS',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4),
      );
}

// ─── Reusable form field ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String                    label;
  final TextEditingController     controller;
  final String                    hint;
  final TextInputType?            keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int                       maxLines;

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
              border: Border.all(
                  color: const Color.fromRGBO(46, 204, 113, 0.35)),
            ),
            child: TextField(
              controller:       controller,
              keyboardType:     keyboardType,
              inputFormatters:  inputFormatters,
              maxLines:         maxLines,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      );
}

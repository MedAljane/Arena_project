import 'package:flutter/material.dart';
import 'admin_colors.dart';

class AdminTheme {
  static ThemeData dark() => ThemeData(
    brightness:       Brightness.dark,
    scaffoldBackgroundColor: AdminColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary:   AdminColors.indigo,
      secondary: AdminColors.neonGreen,
      surface:   AdminColors.darkCard,
      error:     AdminColors.danger,
    ),
    fontFamily: 'DM Sans',
    textTheme:  _textTheme(AdminColors.darkText, AdminColors.darkMuted),
    cardTheme: const CardThemeData(
      color:       AdminColors.darkCard,
      elevation:   0,
      shape: RoundedRectangleBorder(
        side:        BorderSide(color: AdminColors.darkBorder),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AdminColors.darkInput,
      contentPadding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border:          _inputBorder(AdminColors.darkBorder),
      enabledBorder:   _inputBorder(AdminColors.darkBorder),
      focusedBorder:   _inputBorder(AdminColors.indigo, width: 1.5),
      errorBorder:     _inputBorder(AdminColors.danger),
      hintStyle:       const TextStyle(color: AdminColors.darkSubtle, fontSize: 14),
      labelStyle:      const TextStyle(color: AdminColors.darkMuted,  fontSize: 13),
    ),
    dividerColor:     AdminColors.darkBorder,
    iconTheme:        const IconThemeData(color: AdminColors.darkMuted),
    extensions: const [AdminExt(
      bg:      AdminColors.darkBg,
      card:    AdminColors.darkCard,
      border:  AdminColors.darkBorder,
      text:    AdminColors.darkText,
      muted:   AdminColors.darkMuted,
      subtle:  AdminColors.darkSubtle,
      input:   AdminColors.darkInput,
      hover:   Color(0x18FFFFFF),
    )],
  );

  static ThemeData light() => ThemeData(
    brightness:       Brightness.light,
    scaffoldBackgroundColor: AdminColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary:   AdminColors.indigo,
      secondary: AdminColors.neonGreen,
      surface:   AdminColors.lightCard,
      error:     AdminColors.danger,
    ),
    fontFamily: 'DM Sans',
    textTheme:  _textTheme(AdminColors.lightText, AdminColors.lightMuted),
    cardTheme: const CardThemeData(
      color:    AdminColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side:         BorderSide(color: AdminColors.lightBorder),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:         true,
      fillColor:      AdminColors.lightInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border:         _inputBorder(AdminColors.lightBorder),
      enabledBorder:  _inputBorder(AdminColors.lightBorder),
      focusedBorder:  _inputBorder(AdminColors.indigo, width: 1.5),
      errorBorder:    _inputBorder(AdminColors.danger),
      hintStyle:      const TextStyle(color: AdminColors.lightSubtle, fontSize: 14),
      labelStyle:     const TextStyle(color: AdminColors.lightMuted,  fontSize: 13),
    ),
    dividerColor:    AdminColors.lightBorder,
    iconTheme:       const IconThemeData(color: AdminColors.lightMuted),
    extensions: const [AdminExt(
      bg:     AdminColors.lightBg,
      card:   AdminColors.lightCard,
      border: AdminColors.lightBorder,
      text:   AdminColors.lightText,
      muted:  AdminColors.lightMuted,
      subtle: AdminColors.lightSubtle,
      input:  AdminColors.lightInput,
      hover:  Color(0x0A000000),
    )],
  );

  static OutlineInputBorder _inputBorder(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   BorderSide(color: c, width: width),
      );

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge:  TextStyle(color: primary, fontWeight: FontWeight.w800),
    headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w700),
    titleLarge:    TextStyle(color: primary, fontWeight: FontWeight.w600),
    titleMedium:   TextStyle(color: primary, fontWeight: FontWeight.w600),
    bodyLarge:     TextStyle(color: primary),
    bodyMedium:    TextStyle(color: secondary),
    bodySmall:     TextStyle(color: secondary, fontSize: 12),
    labelLarge:    TextStyle(color: primary, fontWeight: FontWeight.w600),
    labelSmall:    TextStyle(color: secondary, fontSize: 11, letterSpacing: 0.8),
  );
}

/// Theme extension so widgets can read semantic tokens without hard-coding colours.
@immutable
class AdminExt extends ThemeExtension<AdminExt> {
  const AdminExt({
    required this.bg, required this.card, required this.border,
    required this.text, required this.muted, required this.subtle,
    required this.input, required this.hover,
  });
  final Color bg, card, border, text, muted, subtle, input, hover;

  @override
  AdminExt copyWith({Color? bg, Color? card, Color? border,
      Color? text, Color? muted, Color? subtle, Color? input, Color? hover}) =>
    AdminExt(
      bg:     bg ?? this.bg,
      card:   card ?? this.card,
      border: border ?? this.border,
      text:   text ?? this.text,
      muted:  muted ?? this.muted,
      subtle: subtle ?? this.subtle,
      input:  input ?? this.input,
      hover:  hover ?? this.hover,
    );

  @override
  AdminExt lerp(AdminExt? other, double t) {
    if (other == null) return this;
    return AdminExt(
      bg:     Color.lerp(bg, other.bg, t)!,
      card:   Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      text:   Color.lerp(text, other.text, t)!,
      muted:  Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      input:  Color.lerp(input, other.input, t)!,
      hover:  Color.lerp(hover, other.hover, t)!,
    );
  }
}

/// Convenience extension on [BuildContext] to read admin theme tokens.
extension AdminThemeX on BuildContext {
  AdminExt get adminExt =>
      Theme.of(this).extension<AdminExt>() ??
      const AdminExt(
        bg:     AdminColors.darkBg,
        card:   AdminColors.darkCard,
        border: AdminColors.darkBorder,
        text:   AdminColors.darkText,
        muted:  AdminColors.darkMuted,
        subtle: AdminColors.darkSubtle,
        input:  AdminColors.darkInput,
        hover:  Color(0x18FFFFFF),
      );
}

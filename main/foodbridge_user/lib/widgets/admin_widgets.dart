import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';

// ─── Stat card for dashboard ──────────────────────────────────────────────
class AdminStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final String? delta;   // e.g. "+3 today"

  const AdminStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            if (delta != null)
              Text(delta!, style: GoogleFonts.dmSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.syne(
              fontSize: 26, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 12, color: AdminColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AdminSectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.syne(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary)),
            if (subtitle != null)
              Text(subtitle!, style: GoogleFonts.dmSans(
                  fontSize: 12, color: AdminColors.textMuted)),
          ],
        )),
        if (action != null) action!,
      ]),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────
class AdminBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const AdminBadge({super.key, required this.label, required this.color,
      required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
        ],
        Text(label, style: GoogleFonts.syne(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.3)),
      ]),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AdminEmptyState({super.key, required this.icon,
      required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AdminColors.bg2, shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.syne(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AdminColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AdminColors.textMuted, height: 1.5)),
        ]),
      ),
    );
  }
}

// ─── Danger action button ─────────────────────────────────────────────────
class DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DangerButton({super.key, required this.label,
      required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AdminColors.coralL,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.coral.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AdminColors.coral),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.syne(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AdminColors.coral)),
        ]),
      ),
    );
  }
}

// ─── Success action button ────────────────────────────────────────────────
class SuccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Color? bg;

  const SuccessButton({super.key, required this.label, required this.icon,
      required this.onTap, this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    final c  = color ?? AdminColors.accent;
    final bg2 = bg ?? AdminColors.accentL;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.syne(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────
class AdminLoadingCard extends StatelessWidget {
  const AdminLoadingCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    height: 80,
    decoration: BoxDecoration(
      color: AdminColors.bg2,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

// ─── Confirm dialog ───────────────────────────────────────────────────────
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirm',
  Color confirmColor  = AdminColors.coral,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title, style: GoogleFonts.syne(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary)),
      content: Text(body, style: GoogleFonts.dmSans(
          fontSize: 14, color: AdminColors.textSecondary, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: GoogleFonts.syne(
              color: AdminColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ) ?? false;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

// ─── Section header ───────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.syne(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── App Card ─────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({super.key, required this.child, this.padding,
      this.color, this.onTap, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.cardBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 3),
          )],
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const StatusBadge({super.key, required this.label,
      required this.color, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: GoogleFonts.syne(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── Stat card (used in hero strips) ─────────────────────────────────────
class MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const MiniStatCard({super.key, required this.value, required this.label,
      required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.syne(
                fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.dmSans(
                fontSize: 11, color: color.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              Text(value, style: GoogleFonts.syne(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
            ],
          ),
          const Spacer(),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.dmSans(
              fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.icon,
      required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, 
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            SelectableText(subtitle, textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar circle ────────────────────────────────────────────────────────
class AvatarCircle extends StatelessWidget {
  final String initials;
  final Color bg;
  final Color fg;
  final double size;

  const AvatarCircle({super.key, required this.initials,
      required this.bg, required this.fg, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: GoogleFonts.syne(
          fontSize: size * 0.33, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider, thickness: 0.5);
}

// ─── Loading shimmer-style placeholder ───────────────────────────────────
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Custom FoodBridge Dropdown (FBDropdown) ─────────────────────────────
class FBDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const FBDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: AppColors.textMuted),
              dropdownColor: AppColors.cardBg,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Severity Bar (Progress Indicator) ────────────────────────────────────
class SeverityBar extends StatelessWidget {
  final double? progress;
  final double? fraction; // alias
  final Color color;
  final double height;

  const SeverityBar({
    super.key,
    this.progress,
    this.fraction,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = (progress ?? fraction ?? 0.0).clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: effectiveProgress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// ─── Urgency Badge ────────────────────────────────────────────────────────
class UrgencyBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const UrgencyBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: label, color: color, bg: bg);
  }
}

// ─── Alert Item ───────────────────────────────────────────────────────────
class AlertItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color bg;
  final Color borderColor;
  final Color iconColor;

  const AlertItem({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.bg,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 6),
                Text(time, style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

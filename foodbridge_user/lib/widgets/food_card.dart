import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';
import 'common.dart';

class FoodCard extends StatelessWidget {
  final FoodListing listing;
  final VoidCallback onRequest;

  const FoodCard({super.key, required this.listing, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top color band + emoji ───────────────────────────────────
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: listing.statusBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // large emoji bg
                Positioned(
                  right: 16, top: 10,
                  child: Text(listing.imageEmoji,
                      style: const TextStyle(fontSize: 48)),
                ),
                // donor type chip
                Positioned(
                  left: 14, top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(listing.donorType,
                        style: GoogleFonts.syne(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ),
                ),
                // expiry badge
                Positioned(
                  left: 14, bottom: 12,
                  child: StatusBadge(
                    label: listing.statusLabel,
                    color: listing.statusColor,
                    bg: Colors.white.withOpacity(0.9),
                    icon: listing.expiryStatus == ExpiryStatus.fresh
                        ? Icons.eco_outlined
                        : Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + distance
                Row(
                  children: [
                    Expanded(
                      child: Text(listing.foodType,
                          style: GoogleFonts.syne(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryXL,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_outlined,
                              size: 11, color: AppColors.primary2),
                          const SizedBox(width: 3),
                          Text('${listing.distanceKm} km',
                              style: GoogleFonts.syne(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.primary2)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(listing.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary,
                        height: 1.4)),
                const SizedBox(height: 10),

                // Info row
                Row(
                  children: [
                    _infoChip(Icons.scale_outlined, listing.quantity),
                    const SizedBox(width: 8),
                    _infoChip(Icons.location_on_outlined, listing.location,
                        flex: true),
                  ],
                ),
                const SizedBox(height: 10),

                // Donor + button row
                Row(
                  children: [
                    AvatarCircle(
                      initials: listing.donorName[0],
                      bg: AppColors.primaryL,
                      fg: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(listing.donorName,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                    ),
                    _RequestButton(onTap: onRequest),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {bool flex = false}) {
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
    return flex ? Expanded(child: chip) : chip;
  }
}

class _RequestButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RequestButton({required this.onTap});

  @override
  State<_RequestButton> createState() => _RequestButtonState();
}

class _RequestButtonState extends State<_RequestButton> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _requested ? null : () {
        setState(() => _requested = true);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _requested ? AppColors.primaryL : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _requested ? AppColors.primary3 : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Text(
          _requested ? '✓ Requested' : 'Request Food',
          style: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: _requested ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

/// Surplus Food reporting screen.
/// Saves to Firestore collection "surplus_food".
class SurplusFoodScreen extends StatefulWidget {
  const SurplusFoodScreen({super.key});

  @override
  State<SurplusFoodScreen> createState() => _SurplusFoodScreenState();
}

class _SurplusFoodScreenState extends State<SurplusFoodScreen> {
  final _svc     = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _foodTypeCtrl  = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _quantityCtrl  = TextEditingController();
  final _locationCtrl  = TextEditingController();

  String _expiryStatus = 'Near Expiry';
  bool   _submitting   = false;
  bool   _submitted    = false;

  static const _expiryOptions = ['Fresh', 'Near Expiry', 'Expired'];

  @override
  void dispose() {
    _foodTypeCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Report Surplus Food',
            style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _submitted ? _buildSuccessState() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info banner ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberL,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.amber.withOpacity(0.3), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.volunteer_activism_outlined,
                  size: 16, color: AppColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Have excess food? Report it here so we can match it with people who need it.',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.amber, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Food Type ─────────────────────────────────────────────────
          _fieldLabel('Food Type'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _foodTypeCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter food type' : null,
            decoration: const InputDecoration(
              hintText: 'e.g. Veg Biryani, Bread, Fruits',
              prefixIcon: Icon(Icons.restaurant_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────
          _fieldLabel('Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            validator: (v) =>
                (v == null || v.trim().length < 5) ? 'Please add a brief description' : null,
            decoration: const InputDecoration(
              hintText: 'Briefly describe the food — how it was prepared, condition, etc.',
              alignLabelWithHint: true,
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // ── Quantity ──────────────────────────────────────────────────
          _fieldLabel('Quantity'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _quantityCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter quantity' : null,
            decoration: const InputDecoration(
              hintText: 'e.g. 10 portions, 5kg, 30 packets',
              prefixIcon: Icon(Icons.scale_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // ── Location ──────────────────────────────────────────────────
          _fieldLabel('Pickup Location'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _locationCtrl,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Location is required' : null,
            decoration: const InputDecoration(
              hintText: 'e.g. Indiranagar, 100ft Road',
              prefixIcon: Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),

          // ── Expiry Status ─────────────────────────────────────────────
          _fieldLabel('Expiry Status'),
          const SizedBox(height: 8),
          Row(
            children: _expiryOptions.map((opt) {
              final isSelected = _expiryStatus == opt;
              final color = opt == 'Fresh'
                  ? AppColors.primary2
                  : opt == 'Near Expiry'
                      ? AppColors.amber
                      : AppColors.coral;
              final bg = opt == 'Fresh'
                  ? AppColors.primaryL
                  : opt == 'Near Expiry'
                      ? AppColors.amberL
                      : AppColors.coralL;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _expiryStatus = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(
                        right: opt == _expiryOptions.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : AppColors.bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt == 'Fresh'
                              ? Icons.eco_outlined
                              : opt == 'Near Expiry'
                                  ? Icons.schedule_outlined
                                  : Icons.warning_amber_outlined,
                          size: 18,
                          color: isSelected ? color : AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(opt,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.syne(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Submit ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _handleSubmit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                _submitting ? 'Submitting...' : 'Report Surplus Food',
                style: GoogleFonts.syne(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Success state (same pattern as ReportScreen) ─────────────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.primaryL, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Surplus Food Reported!',
                style: GoogleFonts.syne(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Your surplus has been saved to our database under "surplus_food" and will be matched with nearby requests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(children: [
                _summaryRow(Icons.restaurant_outlined, 'Food Type', _foodTypeCtrl.text),
                const AppDivider(),
                _summaryRow(Icons.scale_outlined, 'Quantity', _quantityCtrl.text),
                const AppDivider(),
                _summaryRow(Icons.location_on_outlined, 'Location', _locationCtrl.text),
                const AppDivider(),
                _summaryRow(Icons.schedule_outlined, 'Expiry', _expiryStatus),
                const AppDivider(),
                _summaryRow(Icons.pending_outlined, 'Status', 'Available'),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _submitted = false;
                  _foodTypeCtrl.clear();
                  _descCtrl.clear();
                  _quantityCtrl.clear();
                  _locationCtrl.clear();
                  _expiryStatus = 'Near Expiry';
                }),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Report Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.syne(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4),
      );

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await _svc.reportSurplusFood(
        foodType:     _foodTypeCtrl.text.trim(),
        description:  _descCtrl.text.trim(),
        quantity:     _quantityCtrl.text.trim(),
        location:     _locationCtrl.text.trim(),
        expiryStatus: _expiryStatus,
      );
      setState(() { _submitting = false; _submitted = true; });
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

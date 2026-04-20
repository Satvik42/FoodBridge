import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

/// New Request screen — navigated to from RequestsScreen FAB.
/// Saves to Firestore collection "requests" with status "pending".
/// Returns the created [FoodRequest] when popped so parent can refresh.
class NewRequestScreen extends StatefulWidget {
  /// Optional pre-filled listing (when tapped from map / food card).
  final FoodListing? listing;

  const NewRequestScreen({super.key, this.listing});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _svc      = FirebaseService();
  final _formKey  = GlobalKey<FormState>();

  final _foodTypeCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();

  bool _submitting = false;

  // Dropdown options
  static const _foodTypes = [
    'Cooked Meal', 'Rice & Dal', 'Bread / Bakery',
    'Fruits & Vegetables', 'Packaged Food', 'Snacks',
    'Beverages', 'Other',
  ];
  static const _quantities = [
    '1–5 portions', '6–10 portions', '11–25 portions',
    '26–50 portions', '50+ portions', 'Custom',
  ];

  String _selectedFoodType = 'Cooked Meal';
  String _selectedQuantity = '1–5 portions';

  @override
  void initState() {
    super.initState();
    // Pre-fill if coming from a listing
    if (widget.listing != null) {
      _foodTypeCtrl.text = widget.listing!.foodType;
      _locationCtrl.text = widget.listing!.location;
      _selectedFoodType  = _foodTypes.contains(widget.listing!.foodType)
          ? widget.listing!.foodType
          : 'Other';
    }
  }

  @override
  void dispose() {
    _foodTypeCtrl.dispose();
    _locationCtrl.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('New Food Request',
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info banner ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryXL,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary3.withOpacity(0.4), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primary2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your request will be saved with status "Pending" and matched to available donations.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.primary, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Food Type dropdown ───────────────────────────────────────
            _fieldLabel('Food Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFoodType,
              items: _foodTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFoodType = v!),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.restaurant_outlined,
                    size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // ── Quantity dropdown ────────────────────────────────────────
            _fieldLabel('Quantity Needed'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedQuantity,
              items: _quantities
                  .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedQuantity = v!),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.scale_outlined,
                    size: 18, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // ── Location ─────────────────────────────────────────────────
            _fieldLabel('Pickup / Delivery Location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Location is required' : null,
              decoration: const InputDecoration(
                hintText: 'e.g. Koramangala, 5th Block',
                prefixIcon: Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.textMuted),
              ),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // ── Notes (optional) ─────────────────────────────────────────
            _fieldLabel('Additional Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Any dietary restrictions, best time for pickup, etc.',
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),

            // ── Submit ───────────────────────────────────────────────────
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
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(
                  _submitting ? 'Submitting...' : 'Submit Request',
                  style: GoogleFonts.syne(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
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
      final request = await _svc.createRequest(
        foodId:   widget.listing?.isSurplus == true
            ? widget.listing!.surplusId
            : widget.listing?.id ?? '',
        foodType: _selectedFoodType,
        location: _locationCtrl.text.trim(),
        quantity: _selectedQuantity,
      );

      if (!mounted) return;
      // Pop and return the created request so RequestsScreen can refresh
      Navigator.pop(context, request);
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit: $e',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }
}

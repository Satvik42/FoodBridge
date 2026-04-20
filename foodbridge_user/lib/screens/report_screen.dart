import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _svc = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  ReportType _reportType = ReportType.spoiledFood;
  bool _hasImage = false;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Report Issue', style: GoogleFonts.syne(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('user_reports', style: GoogleFonts.syne(
                fontSize: 10, color: Colors.white70,
                fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      body: _submitted ? _buildSuccessState() : _buildForm(),
    );
  }

  // ─── Form ────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amberL,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withOpacity(0.3), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  'Your report helps keep food safe. All reports are reviewed and saved to our database.',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.amber, height: 1.5),
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Report type selection
            _sectionLabel('Report Type'),
            const SizedBox(height: 10),
            ...ReportType.values.map((type) => _ReportTypeOption(
              type: type,
              isSelected: _reportType == type,
              onTap: () => setState(() => _reportType = type),
            )),

            const SizedBox(height: 20),

            // Description
            _sectionLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Please describe the issue (min 10 characters)'
                  : null,
              decoration: InputDecoration(
                hintText: 'Describe the issue clearly...\n\nE.g. "The biryani at Indiranagar listing smelled spoiled and had visible mold."',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted),
                alignLabelWithHint: true,
              ),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Image upload
            _sectionLabel('Photo Evidence (Optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _hasImage = !_hasImage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: _hasImage ? AppColors.primaryXL : AppColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasImage
                        ? AppColors.primary2
                        : AppColors.border.withOpacity(0.5),
                    width: _hasImage ? 1.5 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(children: [
                  Icon(
                    _hasImage
                        ? Icons.check_circle_outline_rounded
                        : Icons.camera_alt_outlined,
                    size: 28,
                    color: _hasImage ? AppColors.primary2 : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasImage ? 'Photo attached ✓' : 'Tap to upload photo',
                    style: GoogleFonts.syne(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: _hasImage
                          ? AppColors.primary2
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (!_hasImage) ...[
                    const SizedBox(height: 3),
                    Text('JPG, PNG · Max 5MB',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Firestore schema preview
            _buildSchemaPreview(),
            const SizedBox(height: 24),

            // Submit button
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
                label: Text(_submitting ? 'Submitting...' : 'Submit Report',
                    style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(),
        style: GoogleFonts.syne(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary, letterSpacing: 0.5));
  }

  Widget _buildSchemaPreview() {
    return AppCard(
      color: const Color(0xFF1A2E1A),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.storage_outlined, size: 14, color: Color(0xFF95D5B2)),
            const SizedBox(width: 6),
            Text('Firestore · user_reports',
                style: GoogleFonts.syne(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFF95D5B2))),
          ]),
          const SizedBox(height: 10),
          _schemaLine('userId', '"${FirebaseService().currentUserId}"', true),
          _schemaLine('reportType', '"${_reportType.name}"', false),
          _schemaLine('description', '"${_descCtrl.text.isEmpty ? "..." : _descCtrl.text.substring(0, _descCtrl.text.length.clamp(0, 30))}"', false),
          _schemaLine('timestamp', '"${DateTime.now().toIso8601String().substring(0, 16)}"', false),
          _schemaLine('status', '"pending"', false),
          if (_hasImage) _schemaLine('imageUrl', '"firebase_storage_url"', false),
        ],
      ),
    );
  }

  Widget _schemaLine(String key, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.robotoMono(fontSize: 11),
          children: [
            TextSpan(text: '  $key', style: TextStyle(
                color: highlight
                    ? const Color(0xFF79C0FF)
                    : const Color(0xFF7ECAA1))),
            const TextSpan(text: ': ',
                style: TextStyle(color: Color(0xFF8B949E))),
            TextSpan(text: value,
                style: const TextStyle(color: Color(0xFFF3C68C))),
          ],
        ),
      ),
    );
  }

  // ─── Success State ────────────────────────────────────────────────────────
  Widget _buildSuccessState() {
    final typeLabel = ReportType.values
        .firstWhere((t) => t == _reportType)
        .name;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryL,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Report Submitted!', style: GoogleFonts.syne(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              'Your report has been saved to our database and will be reviewed by our team.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),

            // Report summary card
            AppCard(
              child: Column(children: [
                _summaryRow(Icons.flag_outlined, 'Type',
                    _reportType.name.replaceAllMapped(
                        RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trimLeft()),
                const AppDivider(),
                _summaryRow(Icons.schedule_outlined, 'Status', 'Pending Review'),
                const AppDivider(),
                _summaryRow(Icons.person_outline_rounded, 'Reported by',
                    'User ${FirebaseService().currentUserId}'),
              ]),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _submitted = false;
                  _descCtrl.clear();
                  _hasImage = false;
                  _reportType = ReportType.spoiledFood;
                }),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Submit Another Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
        Text(label, style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: GoogleFonts.syne(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
      ]),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await _svc.submitReport(
      reportType: _reportType,
      description: _descCtrl.text.trim(),
      imageUrl: _hasImage ? 'mock_image_url' : null,
    );
    setState(() { _submitting = false; _submitted = true; });
  }
}

// ─── Report type option card ──────────────────────────────────────────────
class _ReportTypeOption extends StatelessWidget {
  final ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeOption({
    required this.type, required this.isSelected, required this.onTap,
  });

  static const _descriptions = {
    ReportType.spoiledFood: 'Food appears unsafe, spoiled, or has unusual smell/appearance',
    ReportType.incorrectLocation: 'The pickup location on the map is wrong or misleading',
    ReportType.notAvailable: 'Listed food is no longer available at the pickup point',
    ReportType.other: 'Something else that needs attention from our team',
  };

  static const _icons = {
    ReportType.spoiledFood: Icons.warning_amber_outlined,
    ReportType.incorrectLocation: Icons.location_off_outlined,
    ReportType.notAvailable: Icons.no_food_outlined,
    ReportType.other: Icons.help_outline_rounded,
  };

  static const _colors = {
    ReportType.spoiledFood: AppColors.coral,
    ReportType.incorrectLocation: AppColors.amber,
    ReportType.notAvailable: AppColors.blue,
    ReportType.other: AppColors.purple,
  };

  static const _bgs = {
    ReportType.spoiledFood: AppColors.coralL,
    ReportType.incorrectLocation: AppColors.amberL,
    ReportType.notAvailable: AppColors.blueL,
    ReportType.other: AppColors.purpleL,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type]!;
    final bg = _bgs[type]!;
    final icon = _icons[type]!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? bg : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppColors.bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20,
                color: isSelected ? color : AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Build label from enum name
              Text(
                type.name.replaceAllMapped(
                    RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
                    .trimLeft()
                    .replaceFirst(type.name[0], type.name[0].toUpperCase()),
                style: GoogleFonts.syne(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isSelected ? color : AppColors.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(_descriptions[type]!,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isSelected
                          ? color.withOpacity(0.75)
                          : AppColors.textMuted,
                      height: 1.4)),
            ],
          )),
          if (isSelected)
            Icon(Icons.check_circle_rounded, size: 18, color: color),
        ]),
      ),
    );
  }
}

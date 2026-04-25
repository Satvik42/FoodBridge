import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  String _reportType = 'Food Shortage';
  String _ward = 'Rajajinagar';
  String _urgency = 'Critical — needs action now';
  final _familiesCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _foodTypeCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _familiesCtrl.dispose();
    _sourceCtrl.dispose();
    _descCtrl.dispose();
    _foodTypeCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                  title: 'Add Survey / Report',
                  subtitle: 'digitize paper surveys or log field observations'),
              const SizedBox(height: 16),
              _buildForm(),
              const SizedBox(height: 16),
              _buildBulkImport(),
              if (_submitted) ...[
                const SizedBox(height: 16),
                _buildTriageResult(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Community Report',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          FBDropdown(
            label: 'Report Type',
            value: _reportType,
            items: const [
              'Food Shortage',
              'Food Surplus Available',
              'Volunteer Needed',
              'Infrastructure Gap',
              'Delivery Completed',
            ],
            onChanged: (v) => setState(() => _reportType = v!),
          ),
          Row(
            children: [
              Expanded(
                child: FBDropdown(
                  label: 'Ward / Area',
                  value: _ward,
                  items: const [
                    'Rajajinagar',
                    'Malleshwaram',
                    'Indiranagar',
                    'Koramangala',
                    'Whitefield',
                    'Yeshwanthpur',
                    'Other',
                  ],
                  onChanged: (v) => setState(() => _ward = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FBDropdown(
                  label: 'Urgency Level',
                  value: _urgency,
                  items: const [
                    'Critical — needs action now',
                    'High — within 24 hours',
                    'Medium — within a week',
                    'Low — planning',
                  ],
                  onChanged: (v) => setState(() => _urgency = v!),
                ),
              ),
            ],
          ),
          _label('Families / People Affected'),
          TextField(
            controller: _familiesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 25'),
          ),
          const SizedBox(height: 14),
          _label('Source (NGO / Person)'),
          TextField(
            controller: _sourceCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Akshaya Patra · Priya Nair'),
          ),
          const SizedBox(height: 14),
          _label('Description'),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText:
                    'Describe the situation — what is needed, urgency, constraints...'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Food Type (if surplus)'),
                    TextField(
                      controller: _foodTypeCtrl,
                      decoration: const InputDecoration(
                          hintText: 'e.g. Rice, dal, cooked meals'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Quantity / Volume'),
                    TextField(
                      controller: _quantityCtrl,
                      decoration: const InputDecoration(
                          hintText: 'e.g. 80kg or 200 meals'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('Submit & Auto-Match Volunteers →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: GoogleFonts.syne(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.3)),
    );
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted! 2 volunteers notified.',
            style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBulkImport() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bulk CSV Import',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('CSV import — connect to backend',
                    style: GoogleFonts.dmSans(fontSize: 13)),
                backgroundColor: AppColors.textPrimary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.border.withAlpha(60),
                    width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_outlined,
                      size: 28, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('Drop CSV / Excel here',
                      style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Paper survey batch · WhatsApp export',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Supported: .csv, .xlsx, .json · AI auto-tags urgency & zone',
              style:
                  GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTriageResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.greenMid.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text('AI Triage Result',
                  style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 12),
          _triageRow('Urgency', 'Critical'),
          _triageRow('Zone', _ward),
          _triageRow('Matched Volunteers', 'Arun K. (96%), Meera S. (88%)'),
          _triageRow('Recommended Action',
              'Dispatch driving + cooking volunteers within 2 hours'),
          _triageRow('Auto-tagged', 'Food Shortage · Families · Urgent'),
        ],
      ),
    );
  }

  Widget _triageRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textPrimary),
          children: [
            TextSpan(
                text: '$key: ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

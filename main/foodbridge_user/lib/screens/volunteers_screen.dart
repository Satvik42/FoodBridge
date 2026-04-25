import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/data.dart';
import '../widgets/common.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedNeed = 'Rajajinagar — food shortage (CRITICAL)';
  String _selectedSkill = 'Driving / Delivery';
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              Text(
                'Volunteer Matching',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'smart match · skills · location',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _buildMatchEngine(),
              const SizedBox(height: 16),
              _buildRoster(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchEngine() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Match Engine',
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Find by Need'),
                Tab(text: 'Available'),
                Tab(text: 'History'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: _matched ? 460 : 300,
            child: TabBarView(
              controller: _tabController,
              children: [_buildFindTab(), _buildAvailTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Urgent Need"),
            DropdownButton<String>(
              value: _selectedNeed,
              isExpanded: true,
              items:
                  [
                    'Rajajinagar — food shortage (CRITICAL)',
                    'Indiranagar — surplus collection (HIGH)',
                    'Malleshwaram — elderly meals (CRITICAL)',
                    'Koramangala — weekend shift (HIGH)',
                  ].map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNeed = value!;
                  _matched = false;
                });
              },
            ),
          ],
        ),
        FBDropdown(
          label: 'Required Skills',
          value: _selectedSkill,
          items: const [
            'Driving / Delivery',
            'Cooking / Meal Prep',
            'Community Outreach',
            'Logistics / Loading',
          ],
          onChanged: (v) => setState(() {
            _selectedSkill = v!;
            _matched = false;
          }),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _matched = true),
            child: const Text('Find Best Matches →'),
          ),
        ),
        if (_matched) ...[const SizedBox(height: 16), _buildMatchResults()],
      ],
    );
  }

  Widget _buildMatchResults() {
    final matches = sampleVolunteers
        .where((v) => v.isAvailable)
        .take(3)
        .toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 124, 190, 25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greenMid.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Matches Found',
            style: GoogleFonts.syne(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 10),
          ...matches.map(
            (v) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AvatarCircle(
                    initials: v.initials,
                    bg: v.avatarBg,
                    fg: v.avatarText,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${v.distanceKm} · ${v.skills}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${v.matchScore}%',
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showNotifiedSnack(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
              child: const Text('Notify All Matches'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifiedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notifications sent to 3 volunteers!',
          style: GoogleFonts.dmSans(fontSize: 13),
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAvailTab() {
    final avail = sampleVolunteers.where((v) => v.isAvailable).toList();
    return Column(children: avail.map((v) => _VolunteerCard(vol: v)).toList());
  }

  Widget _buildHistoryTab() {
    final hist = [
      {
        'vol': 'Arun K.',
        'task': 'Indiranagar surplus pickup',
        'date': 'Today 09:30',
        'score': '96%',
      },
      {
        'vol': 'Meera S.',
        'task': 'Malleshwaram meals delivery',
        'date': 'Yesterday',
        'score': '88%',
      },
      {
        'vol': 'Suresh T.',
        'task': 'Whitefield distribution',
        'date': '2 days ago',
        'score': '91%',
      },
    ];
    return Column(
      children: hist
          .map(
            (h) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${h['vol']} · ${h['task']}',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          h['date']!,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: h['score']!,
                    color: AppColors.green,
                    bg: AppColors.greenLight,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRoster() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Volunteer Roster',
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${sampleVolunteers.length} registered',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sampleVolunteers.map(
            (v) => _VolunteerCard(vol: v, showAssign: true),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final Volunteer vol;
  final bool showAssign;

  const _VolunteerCard({required this.vol, this.showAssign = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          AvatarCircle(
            initials: vol.initials,
            bg: vol.avatarBg,
            fg: vol.avatarText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vol.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  vol.skills,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                vol.distanceKm,
                style: GoogleFonts.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: vol.isAvailable
                      ? AppColors.greenMid
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              if (vol.isAvailable && showAssign)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Assign',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (!vol.isAvailable)
                Text(
                  'Off-duty',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

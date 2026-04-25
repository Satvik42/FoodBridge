import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models/data.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildNeedsAndAlerts(),
              const SizedBox(height: 16),
              _buildChartsRow(),
              const SizedBox(height: 16),
              _buildCoverage(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Community Overview',
                  style: GoogleFonts.syne(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Bengaluru Metro · Updated 2 mins ago',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('LIVE',
                        style: GoogleFonts.syne(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        StatCard(
          label: 'Critical Needs',
          value: '14',
          subtitle: '↑ 3 from yesterday',
          accentColor: AppColors.coralMid,
          icon: Icons.warning_amber_outlined,
        ),
        StatCard(
          label: 'Food Surplus Alerts',
          value: '7',
          subtitle: '↓ 2 being collected',
          accentColor: AppColors.amberMid,
          icon: Icons.inventory_2_outlined,
        ),
        StatCard(
          label: 'Active Volunteers',
          value: '52',
          subtitle: '↑ 8 deployed today',
          accentColor: AppColors.greenMid,
          icon: Icons.people_outline,
        ),
        StatCard(
          label: 'Families Reached',
          value: '340',
          subtitle: 'this week · 6 zones',
          accentColor: AppColors.blue,
          icon: Icons.home_outlined,
        ),
      ],
    );
  }

  Widget _buildNeedsAndAlerts() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Urgent Needs',
                      style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('ranked by severity',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 14),
              ...sampleNeeds
                  .take(4)
                  .map((n) => _NeedRow(need: n)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alert Feed',
                      style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text('real-time',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 14),
              const AlertItem(
                icon: Icons.error_outline,
                title: 'Critical — Rajajinagar food shortage',
                body: '6 reports confirm 40+ households without meals. 3 volunteers auto-matched.',
                time: '12 min ago · NGO survey batch',
                bg: AppColors.coralLight,
                borderColor: AppColors.coralMid,
                iconColor: AppColors.coralMid,
              ),
              const AlertItem(
                icon: Icons.warning_amber_outlined,
                title: 'Surplus expiry risk — Indiranagar',
                body: 'Chai Point & 2 restaurants flagged 200kg surplus. Collection window: 4 hrs.',
                time: '38 min ago · Field report',
                bg: AppColors.amberLight,
                borderColor: AppColors.amberMid,
                iconColor: AppColors.amberMid,
              ),
              const AlertItem(
                icon: Icons.check_circle_outline,
                title: 'Resolved — Whitefield delivery',
                body: '120 meals distributed. 4 volunteers completed shift.',
                time: '2h ago · Closed by Priya N.',
                bg: AppColors.greenLight,
                borderColor: AppColors.greenMid,
                iconColor: AppColors.greenMid,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Impact — Meals Distributed',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 220,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
                        ];
                        return Text(days[value.toInt()],
                            style: GoogleFonts.dmSans(
                                fontSize: 10, color: AppColors.textMuted));
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.border, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [85, 120, 180, 145, 160, 90, 110]
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: AppColors.green,
                              width: 22,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            )
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverage() {
    final zones = [
      {'name': 'Rajajinagar', 'vols': 2, 'need': 8},
      {'name': 'Koramangala', 'vols': 6, 'need': 7},
      {'name': 'Indiranagar', 'vols': 9, 'need': 9},
      {'name': 'Whitefield', 'vols': 4, 'need': 5},
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volunteer Coverage by Zone',
              style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...zones.map((z) {
            final pct = (z['vols'] as int) / (z['need'] as int);
            final color = pct < 0.4
                ? AppColors.coralMid
                : pct < 0.7
                    ? AppColors.amberMid
                    : AppColors.greenMid;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(z['name'] as String,
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textPrimary)),
                      Text('${z['vols']}/${z['need']} volunteers',
                          style: GoogleFonts.syne(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SeverityBar(fraction: pct, color: color, height: 6),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  final CommunityNeed need;
  const _NeedRow({required this.need});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: need.urgencyColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(need.title,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              UrgencyBadge(
                  label: need.urgencyLabel,
                  color: need.urgencyColor,
                  bg: need.urgencyBg),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(need.location,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 5),
                SeverityBar(
                    fraction: need.severityScore / 100,
                    color: need.urgencyColor),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(height: 0.5, color: AppColors.border),
          ),
        ],
      ),
    );
  }
}

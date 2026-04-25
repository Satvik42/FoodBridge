import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models/data.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
                  title: 'Field Reports',
                  subtitle: 'aggregated from all sources'),
              const SizedBox(height: 16),
              _buildSourceSummary(),
              const SizedBox(height: 16),
              _buildReportsList(),
              const SizedBox(height: 16),
              _buildSourceChart(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSummary() {
    final sources = [
      {'label': 'Paper Surveys', 'count': '127', 'color': AppColors.coralMid},
      {'label': 'NGO Field Reports', 'count': '48', 'color': AppColors.amberMid},
      {'label': 'WhatsApp Bot', 'count': '89', 'color': AppColors.greenMid},
      {'label': 'Direct App', 'count': '34', 'color': AppColors.blue},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: sources.map((s) {
        return Container(
          decoration: BoxDecoration(
            color: (s['color'] as Color).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (s['color'] as Color).withOpacity(0.25), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: s['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(s['count'] as String,
                        style: GoogleFonts.syne(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: s['color'] as Color)),
                    Text(s['label'] as String,
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportsList() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Submissions',
                  style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.coralLight,
                    borderRadius: BorderRadius.circular(4)),
                child: Text('3 NEW',
                    style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sampleReports.map((r) => _ReportRow(report: r)),
        ],
      ),
    );
  }

  Widget _buildSourceChart() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports by Source',
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
                maxY: 150,
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
                      getTitlesWidget: (v, _) {
                        const labels = ['Paper', 'NGO', 'WhatsApp', 'App'];
                        if (v.toInt() >= labels.length) return const SizedBox();
                        return Text(labels[v.toInt()],
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppColors.textMuted));
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
                barGroups: [
                  _bar(0, 127, AppColors.coralMid),
                  _bar(1, 48, AppColors.amberMid),
                  _bar(2, 89, AppColors.greenMid),
                  _bar(3, 34, AppColors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) =>
      BarChartGroupData(x: x, barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 36,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
        )
      ]);
}

class _ReportRow extends StatelessWidget {
  final FieldReport report;
  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: report.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(report.icon, size: 18, color: report.statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${report.source} · ${report.timeAgo}',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: report.statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(report.status,
                    style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: report.statusColor,
                        letterSpacing: 0.3)),
              ),
            ],
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

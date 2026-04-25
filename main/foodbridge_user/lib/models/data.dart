import 'package:flutter/material.dart';
import '../theme.dart';

enum UrgencyLevel { critical, high, medium, low }

class CommunityNeed {
  final String title;
  final String location;
  final UrgencyLevel urgency;
  final int severityScore;
  final int familiesAffected;
  final String reportedAgo;

  const CommunityNeed({
    required this.title,
    required this.location,
    required this.urgency,
    required this.severityScore,
    required this.familiesAffected,
    required this.reportedAgo,
  });

  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.critical:
        return AppColors.coralMid;
      case UrgencyLevel.high:
        return AppColors.amberMid;
      case UrgencyLevel.medium:
        return AppColors.greenMid;
      case UrgencyLevel.low:
        return AppColors.blue;
    }
  }

  Color get urgencyBg {
    switch (urgency) {
      case UrgencyLevel.critical:
        return AppColors.coralLight;
      case UrgencyLevel.high:
        return AppColors.amberLight;
      case UrgencyLevel.medium:
        return AppColors.greenLight;
      case UrgencyLevel.low:
        return AppColors.blueLight;
    }
  }

  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.critical:
        return 'CRITICAL';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.medium:
        return 'MEDIUM';
      case UrgencyLevel.low:
        return 'LOW';
    }
  }
}

class Volunteer {
  final String name;
  final String initials;
  final String skills;
  final String distanceKm;
  final bool isAvailable;
  final Color avatarBg;
  final Color avatarText;
  final int matchScore;

  const Volunteer({
    required this.name,
    required this.initials,
    required this.skills,
    required this.distanceKm,
    required this.isAvailable,
    required this.avatarBg,
    required this.avatarText,
    this.matchScore = 0,
  });
}

class FieldReport {
  final String title;
  final String source;
  final String timeAgo;
  final String type;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;
  final Color iconBg;

  const FieldReport({
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
    required this.iconBg,
  });
}

class AreaZone {
  final String name;
  final int score;
  final String topNeed;
  final double mapX;
  final double mapY;

  const AreaZone({
    required this.name,
    required this.score,
    required this.topNeed,
    required this.mapX,
    required this.mapY,
  });

  Color get scoreColor {
    if (score >= 75) return AppColors.coralMid;
    if (score >= 50) return AppColors.amberMid;
    return AppColors.greenMid;
  }

  Color get bubbleColor {
    if (score >= 75) return AppColors.coralMid.withOpacity(0.22);
    if (score >= 50) return AppColors.amberMid.withOpacity(0.2);
    return AppColors.greenMid.withOpacity(0.18);
  }
}

// — Sample Data —

final List<CommunityNeed> sampleNeeds = [
  const CommunityNeed(
    title: 'Food shortage — 40+ families',
    location: 'Rajajinagar Ward 22',
    urgency: UrgencyLevel.critical,
    severityScore: 92,
    familiesAffected: 40,
    reportedAgo: '1h ago',
  ),
  const CommunityNeed(
    title: 'Elderly meal delivery gaps',
    location: 'Malleshwaram · 3 NGO reports',
    urgency: UrgencyLevel.critical,
    severityScore: 84,
    familiesAffected: 23,
    reportedAgo: '2h ago',
  ),
  const CommunityNeed(
    title: 'Restaurant surplus uncollected',
    location: 'Indiranagar · 200kg expires tonight',
    urgency: UrgencyLevel.high,
    severityScore: 71,
    familiesAffected: 0,
    reportedAgo: '38m ago',
  ),
  const CommunityNeed(
    title: 'Volunteer shortage — weekend shifts',
    location: 'Koramangala distribution hub',
    urgency: UrgencyLevel.high,
    severityScore: 62,
    familiesAffected: 0,
    reportedAgo: '4h ago',
  ),
  const CommunityNeed(
    title: 'Cold storage capacity needed',
    location: 'Yeshwanthpur · planning phase',
    urgency: UrgencyLevel.medium,
    severityScore: 38,
    familiesAffected: 0,
    reportedAgo: '1d ago',
  ),
];

final List<Volunteer> sampleVolunteers = [
  Volunteer(
    name: 'Arun Kumar',
    initials: 'AK',
    skills: 'Driving · Delivery',
    distanceKm: '1.2 km',
    isAvailable: true,
    avatarBg: AppColors.greenLight,
    avatarText: AppColors.green,
    matchScore: 96,
  ),
  Volunteer(
    name: 'Meera Sharma',
    initials: 'MS',
    skills: 'Cooking · Outreach',
    distanceKm: '2.1 km',
    isAvailable: true,
    avatarBg: AppColors.amberLight,
    avatarText: AppColors.amber,
    matchScore: 88,
  ),
  Volunteer(
    name: 'Ravi Pillai',
    initials: 'RP',
    skills: 'Logistics · Loading',
    distanceKm: '3.0 km',
    isAvailable: true,
    avatarBg: AppColors.coralLight,
    avatarText: AppColors.coral,
    matchScore: 81,
  ),
  Volunteer(
    name: 'Divya Nair',
    initials: 'DN',
    skills: 'Community Lead',
    distanceKm: '4.2 km',
    isAvailable: false,
    avatarBg: AppColors.blueLight,
    avatarText: AppColors.blue,
    matchScore: 74,
  ),
  Volunteer(
    name: 'Suresh T.',
    initials: 'ST',
    skills: 'Driving · Cooking',
    distanceKm: '0.8 km',
    isAvailable: true,
    avatarBg: AppColors.greenLight,
    avatarText: AppColors.green,
    matchScore: 91,
  ),
  Volunteer(
    name: 'Pooja M.',
    initials: 'PM',
    skills: 'Medical · Outreach',
    distanceKm: '5.5 km',
    isAvailable: false,
    avatarBg: AppColors.amberLight,
    avatarText: AppColors.amber,
    matchScore: 67,
  ),
];

final List<FieldReport> sampleReports = [
  FieldReport(
    title: '40 families without meals — Rajajinagar',
    source: 'NGO: Akshaya Patra · Ward 22',
    timeAgo: '1h ago',
    type: 'Food Shortage',
    status: 'NEW',
    statusColor: AppColors.coral,
    statusBg: AppColors.coralLight,
    icon: Icons.restaurant_outlined,
    iconBg: AppColors.coralLight,
  ),
  FieldReport(
    title: '200kg surplus — Indiranagar restaurant cluster',
    source: 'Field worker: Kiran · Expires 6PM today',
    timeAgo: '38m ago',
    type: 'Food Surplus',
    status: 'PENDING',
    statusColor: AppColors.amber,
    statusBg: AppColors.amberLight,
    icon: Icons.inventory_2_outlined,
    iconBg: AppColors.amberLight,
  ),
  FieldReport(
    title: 'Weekend volunteer request — Koramangala hub',
    source: 'Coordinator: Deepa S. · 3 slots needed',
    timeAgo: '3h ago',
    type: 'Volunteer Need',
    status: 'REVIEW',
    statusColor: AppColors.blue,
    statusBg: AppColors.blueLight,
    icon: Icons.people_outline,
    iconBg: AppColors.blueLight,
  ),
  FieldReport(
    title: 'Batch survey digitized — 23 households',
    source: 'Paper survey batch · Malleshwaram',
    timeAgo: '3h ago',
    type: 'Survey',
    status: 'DONE',
    statusColor: AppColors.green,
    statusBg: AppColors.greenLight,
    icon: Icons.assignment_outlined,
    iconBg: AppColors.greenLight,
  ),
  FieldReport(
    title: 'Delivery confirmed — 120 meals to Whitefield',
    source: 'Volunteer: Arun K. · Completed',
    timeAgo: '2h ago',
    type: 'Delivery',
    status: 'DONE',
    statusColor: AppColors.green,
    statusBg: AppColors.greenLight,
    icon: Icons.check_circle_outline,
    iconBg: AppColors.greenLight,
  ),
];

final List<AreaZone> sampleZones = [
  const AreaZone(
    name: 'Rajajinagar',
    score: 92,
    topNeed: 'Food shortage',
    mapX: 0.22,
    mapY: 0.22,
  ),
  const AreaZone(
    name: 'Malleshwaram',
    score: 81,
    topNeed: 'Elderly meals',
    mapX: 0.40,
    mapY: 0.30,
  ),
  const AreaZone(
    name: 'Indiranagar',
    score: 71,
    topNeed: 'Surplus collection',
    mapX: 0.65,
    mapY: 0.34,
  ),
  const AreaZone(
    name: 'Koramangala',
    score: 55,
    topNeed: 'Weekend volunteers',
    mapX: 0.60,
    mapY: 0.62,
  ),
  const AreaZone(
    name: 'Whitefield',
    score: 38,
    topNeed: 'Cold storage',
    mapX: 0.82,
    mapY: 0.55,
  ),
  const AreaZone(
    name: 'Yeshwanthpur',
    score: 28,
    topNeed: 'Planning phase',
    mapX: 0.18,
    mapY: 0.70,
  ),
];

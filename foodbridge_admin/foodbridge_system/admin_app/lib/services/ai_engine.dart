// ai_engine.dart — FoodBridge AI Decision Engines
// Pure Dart, no external ML dependencies.
// All engines run in the service layer before Firestore writes.
//
// Engines:
//   RoutingEngine      — decides autoRoute + confidence for each food item
//   MatchEngine        — finds best volunteer by distance + performance
//   WasteEngine        — decides biogas vs feed for unclaimable food
//   DemandSupplyMatcher — links pending requests to available surplus
//   InsightEngine      — generates AI insights from AdminStats
//   AutoStatusEngine   — determines if status transitions should fire

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. ROUTING ENGINE
//    Decides where food goes: donation | delivery | biogas | feed
//    Runs at surplus food creation time.
// ═══════════════════════════════════════════════════════════════════════════

class RoutingEngine {
  /// Main decision: given a food item and nearby demand, choose a route.
  ///
  /// Logic:
  ///   - If already expired → biogas immediately
  ///   - If near expiry AND no requests nearby → feed (time-sensitive)
  ///   - If near expiry AND requests exist → high-confidence delivery
  ///   - If large quantity AND many requests → donation (community)
  ///   - If small quantity OR low demand → delivery
  ///   - Default → delivery
  static RouteDecision decide({
    required String expiryStatus,
    required String quantity,
    required int nearbyRequestCount,
    required DateTime timestamp,
    DateTime? expiryTime,
  }) {
    final qty        = _parseQty(quantity);
    final ageMinutes = DateTime.now().difference(timestamp).inMinutes;
    final isExpired  = expiryStatus == 'Expired';
    final isNear     = expiryStatus == 'Near Expiry';

    // Minutes until expiry (null = no deadline)
    int? minsToExpiry;
    if (expiryTime != null) {
      minsToExpiry = expiryTime.difference(DateTime.now()).inMinutes;
    }

    // ── Decision tree ──────────────────────────────────────────────
    if (isExpired) {
      return const RouteDecision(
        route: AutoRoute.biogas,
        confidence: 95,
        reasoning: 'Food is expired — redirected to biogas unit.',
      );
    }

    if (isNear && nearbyRequestCount == 0 && (minsToExpiry != null && minsToExpiry < 60)) {
      return const RouteDecision(
        route: AutoRoute.feed,
        confidence: 88,
        reasoning: 'Near expiry, no requests — redirected to animal feed.',
      );
    }

    if (isNear && nearbyRequestCount > 0) {
      final conf = _clamp(70 + nearbyRequestCount * 5, 70, 97);
      return RouteDecision(
        route: AutoRoute.delivery,
        confidence: conf,
        reasoning: 'Near expiry with $nearbyRequestCount request(s) — urgent delivery.',
      );
    }

    if (qty >= 50 && nearbyRequestCount >= 3) {
      final conf = _clamp(75 + (qty ~/ 20), 75, 95);
      return RouteDecision(
        route: AutoRoute.donation,
        confidence: conf,
        reasoning: 'Large quantity ($qty units) with $nearbyRequestCount requests — community donation.',
      );
    }

    if (nearbyRequestCount == 0 && ageMinutes > 120) {
      return RouteDecision(
        route: autoRouteForWaste(qty),
        confidence: 78,
        reasoning: 'No requests for 2+ hours — waste redirect.',
      );
    }

    final conf = _clamp(60 + nearbyRequestCount * 8 + (isNear ? 10 : 0), 50, 90);
    return RouteDecision(
      route: AutoRoute.delivery,
      confidence: conf,
      reasoning: 'Standard delivery route (demand: $nearbyRequestCount).',
    );
  }

  /// Decide biogas vs animal feed based on food characteristics.
  static AutoRoute autoRouteForWaste(int qty) =>
      qty > 20 ? AutoRoute.biogas : AutoRoute.feed;

  static int _parseQty(String q) {
    final m = RegExp(r'\d+').firstMatch(q);
    return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
  }

  static int _clamp(int v, int min, int max) =>
      v < min ? min : v > max ? max : v;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. MATCH ENGINE
//    Finds the best available volunteer using distance + performance score.
//    Returns confidence score. If ≥ 80, volunteer is auto-assigned.
// ═══════════════════════════════════════════════════════════════════════════

class MatchEngine {
  /// Composite score = distance factor (60%) + performance factor (40%).
  /// Lower distance and higher performance = higher confidence.
  static MatchResult? findBest({
    required double foodLat,
    required double foodLng,
    required List<AppUser> volunteers,
  }) {
    if (volunteers.isEmpty) return null;

    MatchResult? best;
    for (final v in volunteers) {
      if (!v.isAvailable) continue;

      final distKm  = haversine(foodLat, foodLng, v.lat, v.lng);
      final distScore = _distanceScore(distKm);   // 0-100, higher = closer
      final perfScore = v.performanceScore;        // 0-100

      // Weighted composite: 60% distance, 40% performance
      final composite = (distScore * 0.60) + (perfScore * 0.40);
      final conf      = composite.round().clamp(0, 100);

      if (best == null || conf > best.confidence) {
        best = MatchResult(
          volunteerId:      v.uid,
          volunteerName:    v.name,
          distanceKm:       double.parse(distKm.toStringAsFixed(1)),
          performanceScore: perfScore,
          confidence:       conf,
        );
      }
    }
    return best;
  }

  /// Convert km to a 0-100 score. 0km = 100, 10km = 0.
  static double _distanceScore(double km) =>
      (100 - (km * 10)).clamp(0, 100);

  static double haversine(
    double lat1, double lng1, double lat2, double lng2) {
    const r  = 6371.0;
    final dL = _r(lat2 - lat1);
    final dN = _r(lng2 - lng1);
    final a  = math.sin(dL/2)*math.sin(dL/2) +
        math.cos(_r(lat1))*math.cos(_r(lat2))*
        math.sin(dN/2)*math.sin(dN/2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
  }
  static double _r(double d) => d * math.pi / 180;
}

// ─── DATA TYPES FOR ENGINES ──────────────────────────────────────────────

class RouteDecision {
  final AutoRoute route;
  final int confidence;
  final String reasoning;
  const RouteDecision({required this.route, required this.confidence, required this.reasoning});
}

class MatchResult {
  final String volunteerId;
  final String volunteerName;
  final double distanceKm;
  final double performanceScore;
  final int confidence;
  const MatchResult({
    required this.volunteerId,
    required this.volunteerName,
    required this.distanceKm,
    required this.performanceScore,
    required this.confidence,
  });

  bool get shouldAutoAssign => confidence >= 80;
}

class WasteRedirect {
  final String foodId;
  final String foodType;
  final String destination;
  final WasteReason reason;
  final DateTime redirectedAt;
  const WasteRedirect({
    required this.foodId,
    required this.foodType,
    required this.destination,
    required this.reason,
    required this.redirectedAt,
  });
}

class DemandSupplyMatch {
  final String requestId;
  final String surplusId;
  final int matchScore;
  final String reasoning;
  const DemandSupplyMatch({
    required this.requestId,
    required this.surplusId,
    required this.matchScore,
    String? reason,
  }) : reasoning = reason ?? '';
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. WASTE ENGINE
//    Decides biogas vs animal feed for unclaimable food.
//    Also determines the WasteReason.
// ═══════════════════════════════════════════════════════════════════════════

class WasteEngine {
  static const int _noRequestsThresholdHours = 2;

  /// Determine if food should be redirected to waste management.
  /// Returns null if food is still viable for donation/delivery.
  static WasteRedirect? evaluate({
    required String surplusId,
    required String foodType,
    required String expiryStatus,
    required String quantity,
    required DateTime timestamp,
    required int nearbyRequestCount,
    DateTime? expiryTime,
  }) {
    final now        = DateTime.now();
    final ageHours   = now.difference(timestamp).inHours;
    final qty        = _parseQty(quantity);
    final isExpired  = expiryStatus == 'Expired';
    final pastExpiry = expiryTime != null && now.isAfter(expiryTime);

    // Case 1: Explicitly expired
    if (isExpired || pastExpiry) {
      return WasteRedirect(
        foodId: surplusId, foodType: foodType,
        destination: qty > 20 ? 'biogas' : 'feed',
        reason: WasteReason.expired,
        redirectedAt: now,
      );
    }

    // Case 2: Sat unclaimed too long
    if (ageHours >= _noRequestsThresholdHours && nearbyRequestCount == 0) {
      return WasteRedirect(
        foodId: surplusId, foodType: foodType,
        destination: qty > 15 ? 'biogas' : 'feed',
        reason: WasteReason.noRequestsLong,
        redirectedAt: now,
      );
    }

    return null; // still viable
  }

  static int _parseQty(String q) {
    final m = RegExp(r'\d+').firstMatch(q);
    return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. DEMAND-SUPPLY MATCHER
//    Links pending requests to available surplus food.
//    Runs whenever a new request or surplus item is created.
// ═══════════════════════════════════════════════════════════════════════════

class DemandSupplyMatcher {
  /// Find the best surplus food item to match a given request.
  static DemandSupplyMatch? matchRequest({
    required FoodRequest request,
    required List<SurplusFood> availableSurplus,
  }) {
    DemandSupplyMatch? best;
    int bestScore = 0;

    for (final s in availableSurplus) {
      if (s.status != 'available') continue;

      int score = 0;

      // Food type similarity (exact = 40, partial = 20)
      if (s.foodType.toLowerCase() == request.foodType.toLowerCase()) {
        score += 40;
      } else if (s.foodType.toLowerCase().contains(
              request.foodType.toLowerCase().split(' ').first)) {
        score += 20;
      }

      // Location proximity (same area = 30)
      if (s.location.toLowerCase().contains(
              request.location.toLowerCase().split(',').first.toLowerCase())) {
        score += 30;
      }

      // Not expired (fresh = 20, near expiry = 10)
      if (s.expiryStatus == 'Fresh')        score += 20;
      else if (s.expiryStatus == 'Near Expiry') score += 10;

      // Quantity sufficiency
      final reqQty = _parseQty(request.quantity);
      final supQty = _parseQty(s.quantity);
      if (supQty >= reqQty) score += 10;

      if (score > bestScore && score >= 40) { // minimum threshold
        bestScore = score;
        best = DemandSupplyMatch(
          requestId: request.id,
          surplusId: s.id,
          matchScore: score,
          reason: _buildReason(score, s, request),
        );
      }
    }
    return best;
  }

  /// Find the best pending request to match a given surplus item.
  static DemandSupplyMatch? matchSurplus({
    required SurplusFood surplus,
    required List<FoodRequest> pendingRequests,
  }) {
    DemandSupplyMatch? best;
    int bestScore = 0;

    for (final r in pendingRequests) {
      if (r.status != RequestStatus.pending) continue;

      int score = 0;

      // Type match
      if (r.foodType.toLowerCase() == surplus.foodType.toLowerCase()) {
        score += 40;
      } else if (r.foodType.toLowerCase().contains(
              surplus.foodType.toLowerCase().split(' ').first)) {
        score += 15;
      }

      // Location
      if (r.location.toLowerCase().contains(
              surplus.location.toLowerCase().split(',').first.toLowerCase())) {
        score += 30;
      }

      // Priority bonus
      if (r.priority == Priority.high) score += 15;
      else if (r.priority == Priority.medium) score += 5;

      if (score > bestScore && score >= 40) {
        bestScore = score;
        best = DemandSupplyMatch(
          requestId: r.id,
          surplusId: surplus.id,
          matchScore: score,
          reason: 'Matched ${surplus.foodType} → ${r.location} (score: $score)',
        );
      }
    }
    return best;
  }

  static String _buildReason(int score, SurplusFood s, FoodRequest r) =>
      'AI matched ${s.foodType} at ${s.location} '
      'to request at ${r.location} (score: $score)';

  static int _parseQty(String q) {
    final m = RegExp(r'\d+').firstMatch(q);
    return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. INSIGHT ENGINE
//    Generates human-readable AI insights from real-time stats.
//    Updates every time AdminStats is recomputed.
// ═══════════════════════════════════════════════════════════════════════════

class InsightEngine {
  static List<AiInsight> generate(AdminStats stats) {
    final insights = <AiInsight>[];
    final now      = DateTime.now();
    final hour     = now.hour;

    // ── Critical: waste spike ──────────────────────────────────────
    if (stats.wasteRedirectedCount > 5) {
      insights.add(AiInsight(
        id: 'waste_spike',
        message: 'Food wastage is high today (${stats.wasteRedirectedCount} items). '
            'Consider notifying more volunteers.',
        severity: InsightSeverity.critical,
        icon: Icons.warning_amber_outlined,
        actionLabel: 'Recruit Volunteers',
        generatedAt: now,
      ));
    }

    // ── Warning: low volunteer coverage ───────────────────────────
    if (stats.activeRequests > 0 && stats.activeVolunteers == 0) {
      insights.add(AiInsight(
        id: 'no_volunteers',
        message: '${stats.activeRequests} request(s) waiting — no active volunteers available.',
        severity: InsightSeverity.critical,
        icon: Icons.directions_bike_outlined,
        actionLabel: 'Alert Volunteers',
        generatedAt: now,
      ));
    } else if (stats.activeRequests > stats.activeVolunteers * 3) {
      final deficit = stats.activeRequests - stats.activeVolunteers;
      // Find busiest area
      final topArea = _topKey(stats.requestsByArea);
      insights.add(AiInsight(
        id: 'low_coverage',
        message: '${topArea != null ? "Area $topArea needs" : "System needs"} '
            'more volunteers — $deficit unmatched requests.',
        severity: InsightSeverity.warning,
        icon: Icons.directions_bike_outlined,
        generatedAt: now,
      ));
    }

    // ── Warning: expired items piling up ──────────────────────────
    if (stats.expiredItems > 3) {
      insights.add(AiInsight(
        id: 'expired_pile',
        message: '${stats.expiredItems} items expired. '
            'Reduce listing-to-pickup time to prevent waste.',
        severity: InsightSeverity.warning,
        icon: Icons.hourglass_empty,
        generatedAt: now,
      ));
    }

    // ── Info: peak demand time ─────────────────────────────────────
    if (hour >= 11 && hour <= 14) {
      insights.add(AiInsight(
        id: 'peak_lunch',
        message: 'Peak demand time: lunch hours (11AM–2PM). '
            'Expect ${stats.activeRequests + 5}+ requests in next 30 mins.',
        severity: InsightSeverity.info,
        icon: Icons.access_time,
        generatedAt: now,
      ));
    } else if (hour >= 18 && hour <= 21) {
      insights.add(AiInsight(
        id: 'peak_dinner',
        message: 'Peak demand time: dinner hours (6PM–9PM). '
            'Pre-assign volunteers to high-demand areas.',
        severity: InsightSeverity.info,
        icon: Icons.access_time,
        generatedAt: now,
      ));
    }

    // ── Info: top performing volunteer ────────────────────────────
    if (stats.volunteerPerformance.isNotEmpty) {
      final top = stats.volunteerPerformance.first;
      if (top.tasksCompleted > 0) {
        insights.add(AiInsight(
          id: 'top_volunteer',
          message: '🏆 ${top.volunteerName} leads with ${top.tasksCompleted} deliveries '
              '(avg ${top.avgDeliveryMinutes.toStringAsFixed(0)}m).',
          severity: InsightSeverity.info,
          icon: Icons.star_outline,
          generatedAt: now,
        ));
      }
    }

    // ── Info: high-demand area ─────────────────────────────────────
    final topArea = _topKey(stats.requestsByArea);
    if (topArea != null && (stats.requestsByArea[topArea] ?? 0) >= 3) {
      insights.add(AiInsight(
        id: 'hotspot_$topArea',
        message: '$topArea is a high-demand hotspot '
            '(${stats.requestsByArea[topArea]} requests). '
            'Station a volunteer nearby.',
        severity: InsightSeverity.warning,
        icon: Icons.location_on_outlined,
        generatedAt: now,
      ));
    }

    // ── Info: efficiency ─────────────────────────────────────────
    if (stats.avgDeliveryMinutes > 0 && stats.avgDeliveryMinutes < 25) {
      insights.add(AiInsight(
        id: 'fast_delivery',
        message: 'Excellent! Average delivery time is '
            '${stats.avgDeliveryMinutes.toStringAsFixed(0)} mins today.',
        severity: InsightSeverity.info,
        icon: Icons.check_circle_outline,
        generatedAt: now,
      ));
    } else if (stats.avgDeliveryMinutes > 60) {
      insights.add(AiInsight(
        id: 'slow_delivery',
        message: 'Average delivery time is high '
            '(${stats.avgDeliveryMinutes.toStringAsFixed(0)}m). '
            'Volunteers may need reassignment.',
        severity: InsightSeverity.warning,
        icon: Icons.timer_outlined,
        generatedAt: now,
      ));
    }

    // ── Info: food saved milestone ────────────────────────────────
    if (stats.foodSavedCount > 0 && stats.foodSavedCount % 10 == 0) {
      insights.add(AiInsight(
        id: 'milestone_${ stats.foodSavedCount}',
        message: '🎉 Milestone: ${stats.foodSavedCount} food items saved from waste!',
        severity: InsightSeverity.info,
        icon: Icons.eco_outlined,
        generatedAt: now,
      ));
    }

    // Sort: critical first, then warning, then info
    insights.sort((a, b) {
      const order = {
        InsightSeverity.critical: 0,
        InsightSeverity.warning: 1,
        InsightSeverity.info: 2,
      };
      return (order[a.severity] ?? 2).compareTo(order[b.severity] ?? 2);
    });

    return insights.take(6).toList(); // cap at 6
  }

  static String? _topKey(Map<String, int> m) {
    if (m.isEmpty) return null;
    return m.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. AUTO STATUS ENGINE
//    Determines if a status transition should happen automatically.
// ═══════════════════════════════════════════════════════════════════════════

class AutoStatusEngine {
  /// Should this surplus food be auto-expired?
  static bool shouldAutoExpire(SurplusFood s) {
    if (s.status != 'available') return false;
    if (s.expiryStatus == 'Expired') return true;
    if (s.expiryTime != null && DateTime.now().isAfter(s.expiryTime!)) return true;
    return false;
  }

  /// Should this request be auto-cancelled (food gone for too long)?
  static bool shouldAutoCancel(FoodRequest r) {
    if (r.status != RequestStatus.pending) return false;
    final age = DateTime.now().difference(r.timestamp).inHours;
    return age > 4; // cancel if pending > 4 hours
  }

  /// Should a task be considered complete based on time since accept?
  /// (Simulates location-based auto-complete when GPS isn't available)
  static bool canAutoComplete(FoodRequest r) {
    if (r.status != RequestStatus.accepted) return false;
    if (r.acceptedTime == null) return false;
    final elapsed = DateTime.now().difference(r.acceptedTime!).inMinutes;
    return elapsed >= 90; // flag for review after 90 min
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. PERFORMANCE ENGINE
//    Updates volunteer performance scores after each delivery.
// ═══════════════════════════════════════════════════════════════════════════

class PerformanceEngine {
  /// Calculate updated performance score based on delivery history.
  ///
  /// Score factors:
  ///   - Delivery speed (relative to avg)   40%
  ///   - Completion rate                     40%
  ///   - Responsiveness (time to accept)    20%
  static double updateScore({
    required double currentScore,
    required int deliveryMinutes,
    required double systemAvgMinutes,
    required int totalTasksCompleted,
    int? acceptDelayMinutes,
  }) {
    double speedFactor;
    if (systemAvgMinutes <= 0) {
      speedFactor = 50;
    } else {
      // Faster than average → high score
      final ratio = deliveryMinutes / systemAvgMinutes;
      speedFactor = (100 - (ratio * 50)).clamp(0, 100);
    }

    // Completion rate improves with volume
    final completionFactor =
        (50 + totalTasksCompleted * 2).clamp(0.0, 100.0).toDouble();

    // Responsiveness
    final responseFactor = acceptDelayMinutes == null
        ? 50.0
        : (100 - acceptDelayMinutes * 2).clamp(0.0, 100.0).toDouble();

    final newScore = (speedFactor * 0.4 +
        completionFactor * 0.4 +
        responseFactor * 0.2);

    // Smooth update: blend current with new (EMA)
    return (currentScore * 0.6 + newScore * 0.4).clamp(0.0, 100.0);
  }
}

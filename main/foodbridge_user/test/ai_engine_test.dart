import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/services/ai_engine.dart';
import '../lib/models/models.dart';

void main() {
  group('RoutingEngine Tests', () {
    test('Expired food goes to biogas', () {
      final decision = RoutingEngine.decide(
        expiryStatus: 'Expired',
        quantity: '50 units',
        nearbyRequestCount: 2,
        timestamp: DateTime.now(),
      );
      expect(decision.route, AutoRoute.biogas);
      expect(decision.confidence, greaterThanOrEqualTo(90));
    });

    test('Near expiry with demand goes to delivery', () {
      final decision = RoutingEngine.decide(
        expiryStatus: 'Near Expiry',
        quantity: '10 units',
        nearbyRequestCount: 5,
        timestamp: DateTime.now(),
      );
      expect(decision.route, AutoRoute.delivery);
      expect(decision.reasoning, contains('urgent delivery'));
    });

    test('Large quantity with high demand goes to donation', () {
      final decision = RoutingEngine.decide(
        expiryStatus: 'Fresh',
        quantity: '100 units',
        nearbyRequestCount: 10,
        timestamp: DateTime.now(),
      );
      expect(decision.route, AutoRoute.donation);
    });
  });

  group('MatchEngine Tests', () {
    final volunteers = [
      AppUser(uid: 'v1', name: 'Close HighPerf', lat: 10.0, lng: 10.0, performanceScore: 90.0, email: '', role: UserRole.volunteer),
      AppUser(uid: 'v2', name: 'Far HighPerf', lat: 20.0, lng: 20.0, performanceScore: 95.0, email: '', role: UserRole.volunteer),
      AppUser(uid: 'v3', name: 'Closer LowPerf', lat: 10.1, lng: 10.1, performanceScore: 40.0, email: '', role: UserRole.volunteer),
    ];

    test('Finds best volunteer based on distance and performance', () {
      final match = MatchEngine.findBest(
        foodLat: 10.05,
        foodLng: 10.05,
        volunteers: volunteers,
      );
      expect(match, isNotNull);
      expect(match!.volunteerId, 'v1'); // Very close and high performance
    });

    test('Confidence is high for ideal matches', () {
       final match = MatchEngine.findBest(
        foodLat: 10.0,
        foodLng: 10.0,
        volunteers: [volunteers[0]],
      );
      expect(match!.confidence, greaterThanOrEqualTo(90));
      expect(match.shouldAutoAssign, isTrue);
    });
  });

  group('WasteEngine Tests', () {
    test('Redirects expired food to waste', () {
      final redirect = WasteEngine.evaluate(
        surplusId: 's1',
        foodType: 'Bread',
        expiryStatus: 'Expired',
        quantity: '50 units',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        nearbyRequestCount: 0,
      );
      expect(redirect, isNotNull);
      expect(redirect!.reason, WasteReason.expired);
    });

    test('Redirects stale items with no requests', () {
      final redirect = WasteEngine.evaluate(
        surplusId: 's2',
        foodType: 'Fruit',
        expiryStatus: 'Fresh',
        quantity: '10 units',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        nearbyRequestCount: 0,
      );
      expect(redirect, isNotNull);
      expect(redirect!.reason, WasteReason.noRequestsLong);
    });
  });

  group('InsightEngine Tests', () {
    test('Generates waste spike insight', () {
      final stats = AdminStats(
        wasteRedirectedCount: 10,
        activeRequests: 5,
        activeVolunteers: 2,
      );
      final insights = InsightEngine.generate(stats);
      expect(insights.any((i) => i.id == 'waste_spike'), isTrue);
      expect(insights.first.severity, InsightSeverity.critical);
    });

    test('Generates low coverage insight', () {
      final stats = AdminStats(
        activeRequests: 10,
        activeVolunteers: 0,
      );
      final insights = InsightEngine.generate(stats);
      expect(insights.any((i) => i.id == 'no_volunteers'), isTrue);
    });
  });

  group('PerformanceEngine Tests', () {
    test('Improves score for fast delivery', () {
      final newScore = PerformanceEngine.updateScore(
        currentScore: 70.0,
        deliveryMinutes: 15,
        systemAvgMinutes: 30,
        totalTasksCompleted: 25,
      );
      expect(newScore, greaterThan(70.0));
    });

    test('Penalizes extremely slow delivery', () {
      final newScore = PerformanceEngine.updateScore(
        currentScore: 70.0,
        deliveryMinutes: 120,
        systemAvgMinutes: 30,
        totalTasksCompleted: 10,
      );
      expect(newScore, lessThan(70.0));
    });
  });
}

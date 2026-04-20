// firebase_service.dart — FoodBridge Smart System
// Features: smart volunteer matching, priority sorting, delivery time tracking,
//           real-time analytics, map intelligence, clean camelCase fields.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _db = FirebaseFirestore.instance;

  String _uid  = '';
  String _name = 'User';
  double _lat  = 12.9716;  // volunteer's current location
  double _lng  = 77.5946;

  void init(String uid, String name, {double lat = 12.9716, double lng = 77.5946}) {
    _uid  = uid;
    _name = name;
    _lat  = lat;
    _lng  = lng;
  }

  void updateLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    if (_uid.isNotEmpty) {
      _db.collection('users').doc(_uid).update({'lat': lat, 'lng': lng})
          .catchError((e) => debugPrint('[FS] updateLocation: $e'));
    }
  }

  String get currentUserId   => _uid;
  String get currentUserName => _name;

  // ═══════════════════════════════════════════════════════════════════
  // SMART VOLUNTEER MATCHING
  // ═══════════════════════════════════════════════════════════════════

  /// Haversine distance between two lat/lng points in km.
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);

  /// Find the best available volunteer for a food location.
  /// Returns null if no volunteers found.
  Future<MatchResult?> findBestVolunteer({
    required double foodLat,
    required double foodLng,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isAvailable', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return null;

      MatchResult? best;
      for (final doc in snap.docs) {
        final d    = doc.data();
        final lat  = (d['lat'] as num?)?.toDouble()  ?? 12.9716;
        final lng  = (d['lng'] as num?)?.toDouble()  ?? 77.5946;
        final dist = _haversine(foodLat, foodLng, lat, lng);
        final score = dist; // simple: nearest = best

        if (best == null || score < best.score) {
          best = MatchResult(
            volunteerId:   doc.id,
            volunteerName: d['name'] as String? ?? 'Volunteer',
            distanceKm:    double.parse(dist.toStringAsFixed(1)),
            score:         score,
          );
        }
      }
      return best;
    } catch (e) {
      debugPrint('[FS] findBestVolunteer: $e');
      return null;
    }
  }

  /// Mark volunteer as unavailable (when they accept a task).
  Future<void> _setVolunteerAvailability(String volunteerId, bool available) async {
    await _db.collection('users').doc(volunteerId).update({
      'isAvailable': available,
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTINGS — priority-sorted real-time stream
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<FoodListing>> listingsStream() {
    return _db
        .collection('surplus_food')
        .where('status', isEqualTo: 'available')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] listingsStream: $e'))
        .map((snap) {
          final live = snap.docs
              .map((d) => SurplusFood.fromFirestore(d.id, d.data()).toFoodListing())
              .toList();
          final all = [...live, ...sampleListings];
          // Sort by priority first, then timestamp
          all.sort((a, b) {
            final pc = a.priority.sortOrder.compareTo(b.priority.sortOrder);
            if (pc != 0) return pc;
            return b.postedAt.compareTo(a.postedAt);
          });
          return all;
        });
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAP INTELLIGENCE — supply + demand heat data
  // ═══════════════════════════════════════════════════════════════════

  /// Returns all available surplus food for map display.
  Stream<List<SurplusFood>> mapSupplyStream() {
    return _db
        .collection('surplus_food')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .handleError((e) => debugPrint('[FS] mapSupplyStream: $e'))
        .map((snap) => snap.docs
            .map((d) => SurplusFood.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Returns pending/accepted requests for map demand display.
  Stream<List<FoodRequest>> mapDemandStream() {
    return _db
        .collection('requests')
        .where('status', whereIn: ['pending', 'accepted'])
        .snapshots()
        .handleError((e) => debugPrint('[FS] mapDemandStream: $e'))
        .map((snap) => snap.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════
  // SURPLUS FOOD — with priority auto-calc + volunteer matching
  // ═══════════════════════════════════════════════════════════════════

  Future<SurplusFood> reportSurplusFood({
    required String foodType,
    required String description,
    required String quantity,
    required String location,
    required String expiryStatus,
    DateTime? preparedTime,
    DateTime? expiryTime,
    double lat = 12.9716,
    double lng = 77.5946,
    String imageEmoji = '🍱',
  }) async {
    final now      = DateTime.now();
    final docRef   = _db.collection('surplus_food').doc();
    final priority = calcSurplusPriority(expiryStatus, quantity);

    // Find best volunteer at write time
    final match = await findBestVolunteer(foodLat: lat, foodLng: lng);

    final surplus = SurplusFood(
      id: docRef.id, createdBy: _uid, createdByName: _name,
      foodType: foodType, description: description, quantity: quantity,
      location: location, expiryStatus: expiryStatus,
      preparedTime: preparedTime ?? now,
      expiryTime: expiryTime, timestamp: now,
      status: 'available', priority: priority,
      suggestedVolunteerId: match?.volunteerId,
      lat: lat, lng: lng, imageEmoji: imageEmoji,
    );

    await docRef.set({
      ...surplus.toFirestore(),
      'timestamp':    FieldValue.serverTimestamp(),
      'preparedTime': FieldValue.serverTimestamp(),
    });

    return surplus;
  }

  Stream<List<SurplusFood>> allSurplusFoodStream() {
    return _db
        .collection('surplus_food')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] allSurplusFoodStream: $e'))
        .map((snap) {
          final list = snap.docs
              .map((d) => SurplusFood.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
          return list;
        });
  }

  // ═══════════════════════════════════════════════════════════════════
  // REQUESTS — with priority, volunteer matching, location area
  // ═══════════════════════════════════════════════════════════════════

  Future<FoodRequest> createRequest({
    required String foodId,
    required String foodType,
    required String location,
    required String quantity,
    String listingId = '',
    double lat = 12.9716,
    double lng = 77.5946,
    String? expiryStatus,
  }) async {
    final docRef  = _db.collection('requests').doc();
    final now     = DateTime.now();
    final fid     = foodId.isNotEmpty ? foodId : (listingId.isNotEmpty ? listingId : docRef.id);
    final priority = calcRequestPriority(now, expiryStatus);

    // Extract area from location string (first part before comma)
    final area = location.contains(',')
        ? location.split(',').first.trim()
        : location.trim();

    // Find best volunteer
    final match = await findBestVolunteer(foodLat: lat, foodLng: lng);

    final req = FoodRequest(
      id: docRef.id, foodId: fid, userId: _uid,
      foodType: foodType, location: location,
      quantity: quantity, status: RequestStatus.pending,
      timestamp: now, priority: priority,
      suggestedVolunteerId: match?.volunteerId,
      lat: lat, lng: lng, locationArea: area,
    );

    await docRef.set({
      ...req.toFirestore(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    return req;
  }

  Future<void> submitRequest({
    required String listingId,
    required String foodType,
    required String location,
    required String quantity,
  }) async {
    await createRequest(
      foodId: listingId, foodType: foodType,
      location: location, quantity: quantity,
    );
  }

  // ── User: own requests, priority-sorted ────────────────────────────
  Stream<List<FoodRequest>> userRequestsStream() {
    return _db
        .collection('requests')
        .where('userId', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] userRequestsStream: $e'))
        .map((snap) {
          final list = snap.docs
              .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
              .toList();
          // Active first, then by priority
          list.sort((a, b) {
            if (a.status == RequestStatus.completed &&
                b.status != RequestStatus.completed) return 1;
            if (b.status == RequestStatus.completed &&
                a.status != RequestStatus.completed) return -1;
            return a.priority.sortOrder.compareTo(b.priority.sortOrder);
          });
          return list;
        });
  }

  // ── Volunteer: active tasks (pending + own accepted) ───────────────
  // Suggested tasks for this volunteer are sorted to top.
  Stream<List<FoodRequest>> activeTasksStream() {
    final pendingS = _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
            .toList());

    final acceptedS = _db
        .collection('requests')
        .where('acceptedBy', isEqualTo: _uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((s) => s.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
            .toList());

    List<FoodRequest> pending  = [];
    List<FoodRequest> accepted = [];
    late StreamController<List<FoodRequest>> ctrl;

    void push() {
      final all = [...accepted, ...pending];
      all.sort((a, b) {
        // My accepted tasks first
        if (a.status == RequestStatus.accepted &&
            b.status != RequestStatus.accepted) return -1;
        if (b.status == RequestStatus.accepted &&
            a.status != RequestStatus.accepted) return 1;
        // Suggested for me next
        final aSugg = a.suggestedVolunteerId == _uid ? 0 : 1;
        final bSugg = b.suggestedVolunteerId == _uid ? 0 : 1;
        if (aSugg != bSugg) return aSugg.compareTo(bSugg);
        // Then by priority
        final pc = a.priority.sortOrder.compareTo(b.priority.sortOrder);
        if (pc != 0) return pc;
        return a.timestamp.compareTo(b.timestamp);
      });
      ctrl.add(all);
    }

    ctrl = StreamController<List<FoodRequest>>.broadcast(
      onListen: () {
        pendingS .listen((v) { pending  = v; push(); },
            onError: (e) => debugPrint('[FS] activeTasksStream pending: $e'));
        acceptedS.listen((v) { accepted = v; push(); },
            onError: (e) => debugPrint('[FS] activeTasksStream accepted: $e'));
      },
    );
    return ctrl.stream;
  }

  // ── Volunteer: completed tasks ─────────────────────────────────────
  Stream<List<FoodRequest>> completedRequestsStream() {
    return _db
        .collection('requests')
        .where('acceptedBy', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .handleError((e) => debugPrint('[FS] completedRequestsStream: $e'))
        .map((snap) {
          final list = snap.docs
              .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) {
            final ta = a.completedTime ?? a.timestamp;
            final tb = b.completedTime ?? b.timestamp;
            return tb.compareTo(ta);
          });
          return list;
        });
  }

  // ── Admin: ALL requests ────────────────────────────────────────────
  Stream<List<FoodRequest>> allRequestsStream() {
    return _db
        .collection('requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] allRequestsStream: $e'))
        .map((snap) {
          final list = snap.docs
              .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) {
            final pc = a.priority.sortOrder.compareTo(b.priority.sortOrder);
            if (pc != 0) return pc;
            return b.timestamp.compareTo(a.timestamp);
          });
          return list;
        });
  }

  Stream<List<UserReport>> allUserReportsStream() {
    return _db
        .collection('user_reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] allUserReportsStream: $e'))
        .map((snap) => snap.docs
            .map((d) => UserReport.fromFirestore(d.id, d.data()))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACCEPT / COMPLETE — with delivery time tracking + availability
  // ═══════════════════════════════════════════════════════════════════

  /// Atomic accept with delivery time tracking.
  /// Marks volunteer as unavailable to prevent double-booking.
  Future<void> acceptTask(String requestId) async {
    final ref = _db.collection('requests').doc(requestId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw Exception('Request not found.');
      final current = snap.data()?['status'] as String? ?? '';
      if (current != 'pending') throw Exception('Task already accepted by someone else.');
      txn.update(ref, {
        'status':        'accepted',
        'acceptedBy':    _uid,
        'volunteerName': _name,
        'acceptedTime':  FieldValue.serverTimestamp(), // NEW: delivery tracking
      });
    });
    // Mark volunteer unavailable
    await _setVolunteerAvailability(_uid, false)
        .catchError((e) => debugPrint('[FS] setAvailability: $e'));
  }

  /// Complete task — records completedTime for delivery duration calc.
  Future<void> completeTask(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status':        'completed',
      'completedTime': FieldValue.serverTimestamp(),
    });
    // Mark volunteer available again
    await _setVolunteerAvailability(_uid, true)
        .catchError((e) => debugPrint('[FS] setAvailability: $e'));
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADMIN CONTROLS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> markSurplusExpired(String surplusId) async {
    final snap = await _db.collection('surplus_food').doc(surplusId).get();
    if (!snap.exists) return;
    final food = SurplusFood.fromFirestore(snap.id, snap.data()!);
    final suggestion = _getSuggestedAction(food);

    await _db.collection('surplus_food').doc(surplusId).update({
      'status':          'expired',
      'suggestedAction': suggestion,
    });
  }

  String _getSuggestedAction(SurplusFood food) {
    final text = (food.foodType + ' ' + food.description).toLowerCase();
    if (text.contains('biryani') ||
        text.contains('dal') ||
        text.contains('soup') ||
        text.contains('juice') ||
        text.contains('cooked') ||
        text.contains('curry')) {
      return 'biogas';
    }
    if (text.contains('bread') ||
        text.contains('vegetable') ||
        text.contains('fruit') ||
        text.contains('organic') ||
        text.contains('dry')) {
      return 'farmer';
    }
    return 'discard';
  }

  Future<void> redirectWaste(String id, String disposalType) async {
    await _db.collection('surplus_food').doc(id).update({
      'status':       'redirected',
      'disposalType': disposalType,
      'redirectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Force assign a specific volunteer to a request.
  Future<void> adminForceAssign(String requestId, String volunteerId, String volunteerName) async {
    await _db.collection('requests').doc(requestId).update({
      'status':        'accepted',
      'acceptedBy':    volunteerId,
      'volunteerName': volunteerName,
      'acceptedTime':  FieldValue.serverTimestamp(),
      'adminOverride': true,
    });
    await _setVolunteerAvailability(volunteerId, false)
        .catchError((e) => debugPrint('[FS] adminForceAssign: $e'));
  }

  Future<void> adminForceComplete(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status':        'completed',
      'completedTime': FieldValue.serverTimestamp(),
      'adminOverride': true,
    });
  }

  Future<void> markExpiredAndCancelRequest(String surplusId, String requestId) async {
    await markSurplusExpired(surplusId);
    await _db.collection('requests').doc(requestId).update({'status': 'cancelled'});
    // Mark volunteer available again
    await _setVolunteerAvailability(_uid, true);
  }

  Future<void> deleteSurplusFood(String surplusId) async =>
      _db.collection('surplus_food').doc(surplusId).delete();

  Future<void> deleteRequest(String requestId) async =>
      _db.collection('requests').doc(requestId).delete();

  Future<void> resolveUserReport(String reportId) async =>
      _db.collection('user_reports').doc(reportId).update({'status': 'resolved'});

  Future<void> deleteUserReport(String reportId) async =>
      _db.collection('user_reports').doc(reportId).delete();

  // ═══════════════════════════════════════════════════════════════════
  // REAL-TIME ADMIN ANALYTICS — upgraded with all new metrics
  // ═══════════════════════════════════════════════════════════════════

  Stream<AdminStats> adminStatsStream() {
    final surplusS  = _db.collection('surplus_food').snapshots();
    final requestsS = _db.collection('requests').snapshots();
    final reportsS  = _db.collection('user_reports').snapshots();
    final usersS    = _db.collection('users').snapshots();

    QuerySnapshot<Map<String, dynamic>>? latestSurplus;
    QuerySnapshot<Map<String, dynamic>>? latestRequests;
    QuerySnapshot<Map<String, dynamic>>? latestReports;
    QuerySnapshot<Map<String, dynamic>>? latestUsers;

    late StreamController<AdminStats> ctrl;

    AdminStats compute() {
      final surplus   = latestSurplus?.docs  ?? [];
      final requests  = latestRequests?.docs ?? [];
      final reports   = latestReports?.docs  ?? [];
      final users     = latestUsers?.docs    ?? [];

      // Active requests
      final activeReqs = requests
          .where((d) => d.data()['status'] == 'pending' || d.data()['status'] == 'accepted')
          .length;

      // Completed
      final completedDocs = requests
          .where((d) => d.data()['status'] == 'completed')
          .toList();

      // Average delivery time
      double avgDelivery = 0.0;
      final timedDeliveries = completedDocs.where((d) {
        final data = d.data();
        return data['acceptedTime'] != null && data['completedTime'] != null;
      }).toList();
      if (timedDeliveries.isNotEmpty) {
        DateTime ts(dynamic v) {
          try { return (v as dynamic).toDate() as DateTime; } catch (_) {
            if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
            return DateTime.now();
          }
        }
        final totalMins = timedDeliveries.fold<int>(0, (sum, d) {
          final data = d.data();
          final a = ts(data['acceptedTime']);
          final c = ts(data['completedTime']);
          return sum + c.difference(a).inMinutes;
        });
        avgDelivery = totalMins / timedDeliveries.length;
      }

      // Expired items
      final expiredItems = surplus
          .where((d) => d.data()['status'] == 'expired')
          .length;

      // Pending user reports
      final pendingReports = reports
          .where((d) => d.data()['status'] == 'pending')
          .length;

      // Active volunteers
      final volunteerIds = users
          .where((d) => d.data()['role'] == 'volunteer')
          .map((d) => d.id)
          .toSet();
      final activeVols = requests
          .where((d) =>
              d.data()['status'] == 'accepted' &&
              volunteerIds.contains(d.data()['acceptedBy']))
          .map((d) => d.data()['acceptedBy'] as String?)
          .whereType<String>()
          .toSet()
          .length;

      // Auto vs manual assignment
      final autoCount = requests
          .where((d) =>
              d.data()['suggestedVolunteerId'] != null &&
              d.data()['suggestedVolunteerId'] == d.data()['acceptedBy'])
          .length;
      final manualCount = completedDocs.length + activeReqs - autoCount;

      // W2R Metrics
      final biogas = surplus.where((d) => d.data()['disposalType'] == 'biogas').length;
      final farmer = surplus.where((d) => d.data()['disposalType'] == 'farmer').length;
      final disc   = surplus.where((d) => d.data()['disposalType'] == 'discard').length;

      // Requests grouped by location area
      final Map<String, int> byArea = {};
      for (final d in requests) {
        final area = d.data()['locationArea'] as String? ?? 'Unknown';
        if (area.isNotEmpty) {
          byArea[area] = (byArea[area] ?? 0) + 1;
        }
      }

      // Volunteer performance
      final Map<String, Map<String, dynamic>> volPerf = {};
      for (final d in completedDocs) {
        final vid  = d.data()['acceptedBy']    as String? ?? '';
        final name = d.data()['volunteerName'] as String? ?? 'Unknown';
        if (vid.isEmpty) continue;
        volPerf.putIfAbsent(vid, () => {'name': name, 'count': 0, 'totalMins': 0});
        volPerf[vid]!['count'] = (volPerf[vid]!['count'] as int) + 1;

        // Add delivery time if available
        if (d.data()['acceptedTime'] != null && d.data()['completedTime'] != null) {
          DateTime ts(dynamic v) {
            try { return (v as dynamic).toDate() as DateTime; } catch (_) {
              if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
              return DateTime.now();
            }
          }
          final a = ts(d.data()['acceptedTime']);
          final c = ts(d.data()['completedTime']);
          volPerf[vid]!['totalMins'] =
              (volPerf[vid]!['totalMins'] as int) + c.difference(a).inMinutes;
        }
      }
      final perfList = volPerf.entries.map((e) => VolunteerPerformance(
        volunteerId:       e.key,
        volunteerName:     e.value['name'] as String,
        tasksCompleted:    e.value['count'] as int,
        avgDeliveryMinutes: e.value['count'] > 0
            ? (e.value['totalMins'] as int) / (e.value['count'] as int)
            : 0.0,
      )).toList()
        ..sort((a, b) => b.tasksCompleted.compareTo(a.tasksCompleted));

      return AdminStats(
        totalReports:        surplus.length,
        activeRequests:      activeReqs,
        completedDeliveries: completedDocs.length,
        activeVolunteers:    activeVols,
        expiredItems:        expiredItems,
        pendingUserReports:  pendingReports,
        avgDeliveryMinutes:  double.parse(avgDelivery.toStringAsFixed(1)),
        autoAssignedCount:   autoCount,
        manualAssignedCount: manualCount.clamp(0, 999999),
        requestsByArea:      byArea,
        volunteerPerformance: perfList,
        totalBiogas:         biogas,
        totalFarmer:         farmer,
        totalDiscarded:      disc,
      );
    }

    ctrl = StreamController<AdminStats>.broadcast(
      onListen: () {
        surplusS .listen((s) { latestSurplus  = s; ctrl.add(compute()); },
            onError: (e) => debugPrint('[FS] adminStats surplus: $e'));
        requestsS.listen((s) { latestRequests = s; ctrl.add(compute()); },
            onError: (e) => debugPrint('[FS] adminStats requests: $e'));
        reportsS .listen((s) { latestReports  = s; ctrl.add(compute()); },
            onError: (e) => debugPrint('[FS] adminStats reports: $e'));
        usersS   .listen((s) { latestUsers    = s; ctrl.add(compute()); },
            onError: (e) => debugPrint('[FS] adminStats users: $e'));
      },
    );
    return ctrl.stream;
  }

  // ── Fetch available volunteers for admin force-assign ──────────────
  Future<List<AppUser>> getAvailableVolunteers() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();
    return snap.docs
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // USER REPORTS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> submitReport({
    required ReportType reportType,
    required String description,
    String? imageUrl,
    String? listingId,
  }) async {
    final ref = _db.collection('user_reports').doc();
    await ref.set({
      'id':          ref.id,
      'userId':      _uid,
      'reportType':  reportType.name,
      'description': description,
      'timestamp':   FieldValue.serverTimestamp(),
      'status':      'pending',
      if (imageUrl  != null) 'imageUrl':  imageUrl,
      if (listingId != null) 'listingId': listingId,
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════

  Future<SearchResult> search(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return SearchResult(listings: sampleListings, surplusFood: const []);

    final snap = await _db
        .collection('surplus_food')
        .where('status', isEqualTo: 'available')
        .get();

    final surplus = snap.docs
        .map((d) => SurplusFood.fromFirestore(d.id, d.data()))
        .where((s) =>
            s.foodType.toLowerCase().contains(q) ||
            s.location.toLowerCase().contains(q) ||
            s.description.toLowerCase().contains(q))
        .toList();

    final listings = [
      ...surplus.map((s) => s.toFoodListing()),
      ...sampleListings.where((l) =>
          l.foodType.toLowerCase().contains(q) ||
          l.location.toLowerCase().contains(q) ||
          l.donorName.toLowerCase().contains(q) ||
          l.description.toLowerCase().contains(q)),
    ];

    return SearchResult(listings: listings, surplusFood: surplus);
  }

  Future<List<AppNotification>> getNotifications() async => sampleNotifications;
}

class SearchResult {
  final List<FoodListing> listings;
  final List<SurplusFood> surplusFood;
  const SearchResult({required this.listings, required this.surplusFood});
  bool get isEmpty => listings.isEmpty && surplusFood.isEmpty;
}

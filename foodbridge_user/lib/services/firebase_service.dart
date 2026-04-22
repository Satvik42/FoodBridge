// firebase_service.dart — FoodBridge AI Automation
// Every write triggers AI engines. 90% of decisions are automated.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'ai_engine.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _db = FirebaseFirestore.instance;

  String _uid  = '';
  String _name = 'User';
  double _lat  = 12.9716;
  double _lng  = 77.5946;

  void init(String uid, String name, {double lat = 12.9716, double lng = 77.5946}) {
    _uid = uid; _name = name; _lat = lat; _lng = lng;
  }
  void updateLocation(double lat, double lng) {
    _lat = lat; _lng = lng;
    if (_uid.isNotEmpty) {
      _db.collection('users').doc(_uid)
          .update({'lat': lat, 'lng': lng})
          .catchError((e) => debugPrint('[FS] location: $e'));
    }
  }

  String get currentUserId   => _uid;
  String get currentUserName => _name;

  // ═══════════════════════════════════════════════════════════════════
  // AI HELPER — fetch volunteers for matching
  // ═══════════════════════════════════════════════════════════════════

  Future<List<AppUser>> _fetchAvailableVolunteers() async {
    try {
      final snap = await _db.collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('isAvailable', isEqualTo: true)
          .get();
      return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[FS] fetchVolunteers: $e');
      return [];
    }
  }

  Future<List<AppUser>> getAvailableVolunteers() async {
    final snap = await _db.collection('users')
        .where('role', isEqualTo: 'volunteer').get();
    return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
  }

  Future<int> _countNearbyRequests(double lat, double lng, String foodType) async {
    try {
      final snap = await _db.collection('requests')
          .where('status', isEqualTo: 'pending')
          .get();
      // Count requests within ~5km (rough bbox check)
      int count = 0;
      for (final d in snap.docs) {
        final rLat = (d.data()['lat'] as num?)?.toDouble() ?? lat;
        final rLng = (d.data()['lng'] as num?)?.toDouble() ?? lng;
        final dist = MatchEngine.haversine(lat, lng, rLat, rLng);
        if (dist <= 5.0) count++;
      }
      return count;
    } catch (_) { return 0; }
  }

  Future<void> _setAvailability(String uid, bool available) async {
    await _db.collection('users').doc(uid)
        .update({'isAvailable': available})
        .catchError((e) => debugPrint('[FS] availability: $e'));
  }

  // ═══════════════════════════════════════════════════════════════════
  // LISTINGS STREAM — priority + route sorted
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<FoodListing>> listingsStream() {
    return _db.collection('surplus_food')
        .where('status', isEqualTo: 'available')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((e) => debugPrint('[FS] listings: $e'))
        .map((snap) {
          final live = snap.docs
              .map((d) => SurplusFood.fromFirestore(d.id, d.data()).toFoodListing())
              .toList();
          final all = [...live, ...sampleListings];
          all.sort((a, b) {
            final pc = a.priority.sortOrder.compareTo(b.priority.sortOrder);
            if (pc != 0) return pc;
            return b.routeConfidence.compareTo(a.routeConfidence);
          });
          return all;
        });
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAP STREAMS
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<SurplusFood>> mapSupplyStream() => _db
      .collection('surplus_food')
      .where('status', isEqualTo: 'available')
      .snapshots()
      .map((s) => s.docs.map((d) => SurplusFood.fromFirestore(d.id, d.data())).toList());

  Stream<List<FoodRequest>> mapDemandStream() => _db
      .collection('requests')
      .where('status', whereIn: ['pending', 'accepted'])
      .snapshots()
      .map((s) => s.docs.map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList());

  // ═══════════════════════════════════════════════════════════════════
  // SURPLUS FOOD — full AI pipeline at creation
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
    final now    = DateTime.now();
    final docRef = _db.collection('surplus_food').doc();

    // ── 1. Priority Engine ─────────────────────────────────────────
    final (priority, priorityScore) = calcPriorityWithScore(
      expiryStatus, quantity,
      timestamp: now, expiryTime: expiryTime,
    );

    // ── 2. Nearby demand count (for routing decision) ──────────────
    final nearbyCount = await _countNearbyRequests(lat, lng, foodType);

    // ── 3. Routing Engine ──────────────────────────────────────────
    final route = RoutingEngine.decide(
      expiryStatus: expiryStatus,
      quantity: quantity,
      nearbyRequestCount: nearbyCount,
      timestamp: now,
      expiryTime: expiryTime,
    );

    // ── 4. Match Engine — find + optionally auto-assign volunteer ──
    final volunteers = await _fetchAvailableVolunteers();
    final match = MatchEngine.findBest(
      foodLat: lat, foodLng: lng, volunteers: volunteers);

    String? suggestedVolId, assignedVolId, assignedVolName;
    if (match != null) {
      suggestedVolId = match.volunteerId;
      if (match.shouldAutoAssign &&
          (route.route == AutoRoute.delivery || route.route == AutoRoute.donation)) {
        assignedVolId   = match.volunteerId;
        assignedVolName = match.volunteerName;
      }
    }

    // ── 5. Demand-Supply Matcher — link to pending request ─────────
    String? matchedRequestId;
    if (nearbyCount > 0) {
      try {
        final reqSnap = await _db.collection('requests')
            .where('status', isEqualTo: 'pending').get();
        final pending = reqSnap.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data()))
            .toList();
        final surplus = SurplusFood(
          id: docRef.id, createdBy: _uid, createdByName: _name,
          foodType: foodType, description: description, quantity: quantity,
          location: location, expiryStatus: expiryStatus,
          preparedTime: preparedTime ?? now, expiryTime: expiryTime,
          timestamp: now, status: 'available',
          priority: priority, priorityScore: priorityScore,
          autoRoute: route.route, routeConfidence: route.confidence,
          lat: lat, lng: lng, imageEmoji: imageEmoji,
        );
        final dsMatch = DemandSupplyMatcher.matchSurplus(
            surplus: surplus, pendingRequests: pending);
        if (dsMatch != null && dsMatch.matchScore >= 60) {
          matchedRequestId = dsMatch.requestId;
          // Update the matched request with the food link
          await _db.collection('requests').doc(dsMatch.requestId)
              .update({'matchedFoodId': docRef.id}).catchError((e) {});
        }
      } catch (e) { debugPrint('[FS] dsMatch: $e'); }
    }

    // ── 6. Waste check — redirect immediately if needed ───────────
    final wasteResult = WasteEngine.evaluate(
      surplusId: docRef.id, foodType: foodType,
      expiryStatus: expiryStatus, quantity: quantity,
      timestamp: now, nearbyRequestCount: nearbyCount,
      expiryTime: expiryTime,
    );

    final finalStatus   = wasteResult != null ? wasteResult.destination : 'available';
    final autoRedirect  = wasteResult != null;
    final wasteType     = wasteResult?.destination;
    final wasteReason   = wasteResult?.reason;

    // ── 7. Build & write ───────────────────────────────────────────
    final surplus = SurplusFood(
      id: docRef.id, createdBy: _uid, createdByName: _name,
      foodType: foodType, description: description, quantity: quantity,
      location: location, expiryStatus: expiryStatus,
      preparedTime: preparedTime ?? now, expiryTime: expiryTime,
      timestamp: now,
      status: autoRedirect ? finalStatus : 'available',
      priority: priority, priorityScore: priorityScore,
      autoRoute: route.route, routeConfidence: route.confidence,
      suggestedVolunteerId: suggestedVolId,
      assignedVolunteerId: assignedVolId,
      assignedVolunteerName: assignedVolName,
      matchedRequestId: matchedRequestId,
      autoRedirect: autoRedirect, wasteType: wasteType, wasteReason: wasteReason,
      lat: lat, lng: lng, imageEmoji: imageEmoji,
    );

    await docRef.set({
      ...surplus.toFirestore(),
      'timestamp': FieldValue.serverTimestamp(),
      'preparedTime': FieldValue.serverTimestamp(),
    });

    // Auto-assign: mark volunteer unavailable if confidence ≥ 80
    if (assignedVolId != null) {
      await _setAvailability(assignedVolId, false)
          .catchError((e) => debugPrint('[FS] setAvail: $e'));
    }

    // Log to waste_redirects collection
    if (autoRedirect && wasteResult != null) {
      _db.collection('waste_redirects').add({
        'foodId': docRef.id, 'foodType': foodType,
        'destination': wasteType, 'reason': wasteReason?.name,
        'timestamp': FieldValue.serverTimestamp(),
      }).catchError((e) {});
    }

    return surplus;
  }

  Stream<List<SurplusFood>> allSurplusFoodStream() => _db
      .collection('surplus_food')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .handleError((e) => debugPrint('[FS] allSurplus: $e'))
      .map((snap) {
        final list = snap.docs
            .map((d) => SurplusFood.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
        return list;
      });

  // ═══════════════════════════════════════════════════════════════════
  // REQUESTS — AI pipeline at creation
  // ═══════════════════════════════════════════════════════════════════

  Future<FoodRequest> createRequest({
    required String foodId,
    required String foodType,
    required String location,
    required String quantity,
    String listingId   = '',
    double lat         = 12.9716,
    double lng         = 77.5946,
    String? expiryStatus,
  }) async {
    final docRef = _db.collection('requests').doc();
    final now    = DateTime.now();
    final fid    = foodId.isNotEmpty ? foodId : (listingId.isNotEmpty ? listingId : docRef.id);
    final area   = location.contains(',') ? location.split(',').first.trim() : location.trim();

    // ── Priority Engine ────────────────────────────────────────────
    final (priority, priorityScore) = calcPriorityWithScore(
      expiryStatus ?? 'Fresh', quantity, timestamp: now);

    // ── Match Engine ───────────────────────────────────────────────
    final volunteers = await _fetchAvailableVolunteers();
    final match = MatchEngine.findBest(foodLat: lat, foodLng: lng, volunteers: volunteers);

    String? suggestedVolId, assignedVolId;
    if (match != null) {
      suggestedVolId = match.volunteerId;
      if (match.shouldAutoAssign) assignedVolId = match.volunteerId;
    }

    // ── Demand-Supply Matcher — link to available surplus ──────────
    String? matchedFoodId;
    try {
      final surpSnap = await _db.collection('surplus_food')
          .where('status', isEqualTo: 'available').get();
      final availableSurplus = surpSnap.docs
          .map((d) => SurplusFood.fromFirestore(d.id, d.data()))
          .toList();
      final tempReq = FoodRequest(
        id: docRef.id, foodId: fid, userId: _uid,
        foodType: foodType, location: location, quantity: quantity,
        status: RequestStatus.pending, timestamp: now,
      );
      final dsMatch = DemandSupplyMatcher.matchRequest(
          request: tempReq, availableSurplus: availableSurplus);
      if (dsMatch != null && dsMatch.matchScore >= 60) {
        matchedFoodId = dsMatch.surplusId;
        await _db.collection('surplus_food').doc(dsMatch.surplusId)
            .update({'matchedRequestId': docRef.id}).catchError((e) {});
      }
    } catch (e) { debugPrint('[FS] dsMatchReq: $e'); }

    final req = FoodRequest(
      id: docRef.id, foodId: fid, userId: _uid,
      foodType: foodType, location: location, quantity: quantity,
      status: RequestStatus.pending, timestamp: now,
      priority: priority, priorityScore: priorityScore,
      suggestedVolunteerId: suggestedVolId,
      assignedVolunteerId: assignedVolId,
      matchedFoodId: matchedFoodId,
      lat: lat, lng: lng, locationArea: area,
    );

    await docRef.set({
      ...req.toFirestore(), 'timestamp': FieldValue.serverTimestamp(),
    });

    return req;
  }

  Future<void> submitRequest({
    required String listingId, required String foodType,
    required String location, required String quantity,
  }) async => createRequest(
    foodId: listingId, foodType: foodType,
    location: location, quantity: quantity,
  );

  // ═══════════════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<FoodRequest>> userRequestsStream() => _db
      .collection('requests')
      .where('userId', isEqualTo: _uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .handleError((e) => debugPrint('[FS] userReqs: $e'))
      .map((snap) {
        final list = snap.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) {
          if (a.status == RequestStatus.completed &&
              b.status != RequestStatus.completed) return 1;
          if (b.status == RequestStatus.completed &&
              a.status != RequestStatus.completed) return -1;
          return a.priority.sortOrder.compareTo(b.priority.sortOrder);
        });
        return list;
      });

  Stream<List<FoodRequest>> activeTasksStream() {
    final pendingS = _db.collection('requests')
        .where('status', isEqualTo: 'pending').snapshots()
        .map((s) => s.docs.map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList());
    final acceptedS = _db.collection('requests')
        .where('acceptedBy', isEqualTo: _uid)
        .where('status', isEqualTo: 'accepted').snapshots()
        .map((s) => s.docs.map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList());

    List<FoodRequest> pending = [], accepted = [];
    late StreamController<List<FoodRequest>> ctrl;
    void push() {
      final all = [...accepted, ...pending];
      all.sort((a, b) {
        if (a.status == RequestStatus.accepted && b.status != RequestStatus.accepted) return -1;
        if (b.status == RequestStatus.accepted && a.status != RequestStatus.accepted) return 1;
        // Suggested/assigned for me first
        final aMe = (a.suggestedVolunteerId == _uid || a.assignedVolunteerId == _uid) ? 0 : 1;
        final bMe = (b.suggestedVolunteerId == _uid || b.assignedVolunteerId == _uid) ? 0 : 1;
        if (aMe != bMe) return aMe.compareTo(bMe);
        return a.priority.sortOrder.compareTo(b.priority.sortOrder);
      });
      ctrl.add(all);
    }
    ctrl = StreamController<List<FoodRequest>>.broadcast(
      onListen: () {
        pendingS .listen((v) { pending  = v; push(); }, onError: (e) => debugPrint('[FS] pending: $e'));
        acceptedS.listen((v) { accepted = v; push(); }, onError: (e) => debugPrint('[FS] accepted: $e'));
      },
    );
    return ctrl.stream;
  }

  Stream<List<FoodRequest>> completedRequestsStream() => _db
      .collection('requests')
      .where('acceptedBy', isEqualTo: _uid)
      .where('status', isEqualTo: 'completed')
      .snapshots()
      .handleError((e) => debugPrint('[FS] completed: $e'))
      .map((snap) {
        final list = snap.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) {
          final ta = a.completedTime ?? a.timestamp;
          final tb = b.completedTime ?? b.timestamp;
          return tb.compareTo(ta);
        });
        return list;
      });

  Stream<List<FoodRequest>> allRequestsStream() => _db
      .collection('requests')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .handleError((e) => debugPrint('[FS] allReqs: $e'))
      .map((snap) {
        final list = snap.docs
            .map((d) => FoodRequest.fromFirestore(d.id, d.data())).toList();
        list.sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
        return list;
      });

  Stream<List<UserReport>> allUserReportsStream() => _db
      .collection('user_reports')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .handleError((e) => debugPrint('[FS] reports: $e'))
      .map((snap) => snap.docs
          .map((d) => UserReport.fromFirestore(d.id, d.data())).toList());

  // ═══════════════════════════════════════════════════════════════════
  // ACCEPT / COMPLETE — with performance scoring
  // ═══════════════════════════════════════════════════════════════════

  /// Atomic accept. If task was auto-assigned to this volunteer, accepts
  /// instantly without showing button (called from stream listener).
  Future<void> acceptTask(String requestId) async {
    final ref = _db.collection('requests').doc(requestId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw Exception('Request not found.');
      final status = snap.data()?['status'] as String? ?? '';
      if (status != 'pending') throw Exception('Task already accepted by someone else.');
      txn.update(ref, {
        'status':        'accepted',
        'acceptedBy':    _uid,
        'volunteerName': _name,
        'acceptedTime':  FieldValue.serverTimestamp(),
      });
    });
    await _setAvailability(_uid, false)
        .catchError((e) => debugPrint('[FS] setAvail: $e'));
  }

  /// Complete task + update volunteer performance score.
  Future<void> completeTask(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status':        'completed',
      'completedTime': FieldValue.serverTimestamp(),
    });
    await _setAvailability(_uid, true)
        .catchError((e) => debugPrint('[FS] setAvail: $e'));
    // Update performance score asynchronously
    _updatePerformanceScore(requestId)
        .catchError((e) => debugPrint('[FS] perf: $e'));
  }

  Future<void> _updatePerformanceScore(String requestId) async {
    final doc  = await _db.collection('requests').doc(requestId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final req  = FoodRequest.fromFirestore(doc.id, data);
    final mins = req.deliveryMinutes;
    if (mins == null) return;

    // Fetch system avg
    final allSnap = await _db.collection('requests')
        .where('status', isEqualTo: 'completed').get();
    double sysAvg = 0;
    int count = 0;
    for (final d in allSnap.docs) {
      final r = FoodRequest.fromFirestore(d.id, d.data());
      if (r.deliveryMinutes != null) {
        sysAvg += r.deliveryMinutes!;
        count++;
      }
    }
    if (count > 0) sysAvg /= count;

    // Volunteer's completed count
    final volSnap = await _db.collection('requests')
        .where('acceptedBy', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed').get();

    final userDoc = await _db.collection('users').doc(_uid).get();
    final current = (userDoc.data()?['performanceScore'] as num?)?.toDouble() ?? 50.0;

    final newScore = PerformanceEngine.updateScore(
      currentScore: current,
      deliveryMinutes: mins,
      systemAvgMinutes: sysAvg,
      totalTasksCompleted: volSnap.docs.length,
    );

    await _db.collection('users').doc(_uid)
        .update({'performanceScore': newScore});
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADMIN CONTROLS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> markSurplusExpired(String id) =>
      _db.collection('surplus_food').doc(id).update({'status': 'expired'});

  Future<void> adminForceAssign(String requestId, String volId, String volName) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'accepted', 'acceptedBy': volId, 'volunteerName': volName,
      'acceptedTime': FieldValue.serverTimestamp(), 'adminOverride': true,
    });
    await _setAvailability(volId, false);
  }

  Future<void> adminForceComplete(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'completed',
      'completedTime': FieldValue.serverTimestamp(),
      'adminOverride': true,
    });
  }

  Future<void> deleteSurplusFood(String id) =>
      _db.collection('surplus_food').doc(id).delete();

  Future<void> deleteRequest(String id) =>
      _db.collection('requests').doc(id).delete();

  Future<void> resolveUserReport(String id) =>
      _db.collection('user_reports').doc(id).update({'status': 'resolved'});

  Future<void> deleteUserReport(String id) =>
      _db.collection('user_reports').doc(id).delete();

  // ── Waste redirect (admin manual) ─────────────────────────────────
  Future<void> redirectToWaste(String surplusId, String destination) async {
    await _db.collection('surplus_food').doc(surplusId).update({
      'status': destination, 'wasteType': destination, 'autoRedirect': false,
    });
    await _db.collection('waste_redirects').add({
      'foodId': surplusId, 'destination': destination,
      'reason': 'adminManual', 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI ANALYTICS STREAM — full stats + AI insights
  // ═══════════════════════════════════════════════════════════════════

  Stream<AdminStats> adminStatsStream() {
    final surplusS  = _db.collection('surplus_food').snapshots();
    final requestsS = _db.collection('requests').snapshots();
    final reportsS  = _db.collection('user_reports').snapshots();
    final usersS    = _db.collection('users').snapshots();
    final wasteS    = _db.collection('waste_redirects').snapshots();

    QuerySnapshot<Map<String, dynamic>>? ls, lr, lrp, lu, lw;
    late StreamController<AdminStats> ctrl;

    AdminStats compute() {
      final surplus  = ls?.docs  ?? [];
      final requests = lr?.docs  ?? [];
      final reports  = lrp?.docs ?? [];
      final users    = lu?.docs  ?? [];
      final wastes   = lw?.docs  ?? [];

      // Active requests
      final active = requests.where((d) =>
        d.data()['status'] == 'pending' || d.data()['status'] == 'accepted').length;

      // Completed
      final completedDocs = requests
          .where((d) => d.data()['status'] == 'completed').toList();

      // Avg delivery
      DateTime _ts(dynamic v) {
        try { return (v as dynamic).toDate() as DateTime; } catch (_) {
          if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
          return DateTime.now();
        }
      }
      final timed = completedDocs.where((d) =>
        d.data()['acceptedTime'] != null && d.data()['completedTime'] != null).toList();
      double avgDel = 0;
      if (timed.isNotEmpty) {
        final total = timed.fold<int>(0, (s, d) {
          final a = _ts(d.data()['acceptedTime']);
          final c = _ts(d.data()['completedTime']);
          return s + c.difference(a).inMinutes;
        });
        avgDel = total / timed.length;
      }

      // Active volunteers
      final volIds = users.where((d) => d.data()['role'] == 'volunteer')
          .map((d) => d.id).toSet();
      final activeVols = requests
          .where((d) => d.data()['status'] == 'accepted' &&
              volIds.contains(d.data()['acceptedBy'])).map((d) =>
          d.data()['acceptedBy']).whereType<String>().toSet().length;

      // Auto vs manual
      final autoCount = completedDocs.where((d) =>
          d.data()['assignedVolunteerId'] != null).length;

      // Waste redirected
      final wasteCount = wastes.length;

      // Food saved
      final foodSaved = completedDocs.length;

      // By area
      final byArea = <String, int>{};
      for (final d in requests) {
        final a = d.data()['locationArea'] as String? ?? '';
        if (a.isNotEmpty) byArea[a] = (byArea[a] ?? 0) + 1;
      }

      // Volunteer performance
      final perf = <String, Map<String, dynamic>>{};
      for (final d in completedDocs) {
        final vid  = d.data()['acceptedBy']    as String? ?? '';
        final name = d.data()['volunteerName'] as String? ?? 'Unknown';
        if (vid.isEmpty) continue;
        perf.putIfAbsent(vid, () => {'name': name, 'count': 0, 'mins': 0, 'score': 50.0});
        perf[vid]!['count'] = (perf[vid]!['count'] as int) + 1;
        if (d.data()['acceptedTime'] != null && d.data()['completedTime'] != null) {
          final a = _ts(d.data()['acceptedTime']);
          final c = _ts(d.data()['completedTime']);
          perf[vid]!['mins'] = (perf[vid]!['mins'] as int) + c.difference(a).inMinutes;
        }
      }
      // Pull live performance scores
      for (final u in users) {
        if (perf.containsKey(u.id)) {
          perf[u.id]!['score'] = (u.data()['performanceScore'] as num?)?.toDouble() ?? 50.0;
        }
      }
      final perfList = perf.entries.map((e) => VolunteerPerformance(
        volunteerId: e.key,
        volunteerName: e.value['name'] as String,
        tasksCompleted: e.value['count'] as int,
        avgDeliveryMinutes: e.value['count'] > 0
            ? (e.value['mins'] as int) / (e.value['count'] as int)
            : 0.0,
        performanceScore: e.value['score'] as double,
      )).toList()
        ..sort((a, b) => b.tasksCompleted.compareTo(a.tasksCompleted));

      final stats = AdminStats(
        totalReports:        surplus.length,
        activeRequests:      active,
        completedDeliveries: completedDocs.length,
        activeVolunteers:    activeVols,
        expiredItems:        surplus.where((d) => d.data()['status'] == 'expired').length,
        pendingUserReports:  reports.where((d) => d.data()['status'] == 'pending').length,
        avgDeliveryMinutes:  double.parse(avgDel.toStringAsFixed(1)),
        autoAssignedCount:   autoCount,
        manualAssignedCount: (completedDocs.length - autoCount).clamp(0, 999999),
        wasteRedirectedCount: wasteCount,
        foodSavedCount:      foodSaved,
        requestsByArea:      byArea,
        volunteerPerformance: perfList,
        aiInsights: const [], // populated below
      );

      // ── InsightEngine ──────────────────────────────────────────
      final insights = InsightEngine.generate(stats);
      return AdminStats(
        totalReports:         stats.totalReports,
        activeRequests:       stats.activeRequests,
        completedDeliveries:  stats.completedDeliveries,
        activeVolunteers:     stats.activeVolunteers,
        expiredItems:         stats.expiredItems,
        pendingUserReports:   stats.pendingUserReports,
        avgDeliveryMinutes:   stats.avgDeliveryMinutes,
        autoAssignedCount:    stats.autoAssignedCount,
        manualAssignedCount:  stats.manualAssignedCount,
        wasteRedirectedCount: stats.wasteRedirectedCount,
        foodSavedCount:       stats.foodSavedCount,
        requestsByArea:       stats.requestsByArea,
        volunteerPerformance: stats.volunteerPerformance,
        aiInsights:           insights,
      );
    }

    ctrl = StreamController<AdminStats>.broadcast(
      onListen: () {
        surplusS .listen((s) { ls  = s; ctrl.add(compute()); }, onError: (e) => debugPrint('[FS] surplus: $e'));
        requestsS.listen((s) { lr  = s; ctrl.add(compute()); }, onError: (e) => debugPrint('[FS] requests: $e'));
        reportsS .listen((s) { lrp = s; ctrl.add(compute()); }, onError: (e) => debugPrint('[FS] reports: $e'));
        usersS   .listen((s) { lu  = s; ctrl.add(compute()); }, onError: (e) => debugPrint('[FS] users: $e'));
        wasteS   .listen((s) { lw  = s; ctrl.add(compute()); }, onError: (e) => debugPrint('[FS] waste: $e'));
      },
    );
    return ctrl.stream;
  }

  // ═══════════════════════════════════════════════════════════════════
  // BATCH AUTOMATION — call periodically (e.g. from admin app)
  // ═══════════════════════════════════════════════════════════════════

  /// Scan all available surplus food and auto-expire / redirect stale items.
  Future<Map<String, int>> runAutoMaintenanceSweep() async {
    int expired = 0, redirected = 0, cancelled = 0;
    try {
      final snap = await _db.collection('surplus_food')
          .where('status', isEqualTo: 'available').get();
      for (final doc in snap.docs) {
        final s = SurplusFood.fromFirestore(doc.id, doc.data());
        if (AutoStatusEngine.shouldAutoExpire(s)) {
          await doc.reference.update({'status': 'expired'});
          expired++;
        } else {
          final reqSnap = await _db.collection('requests')
              .where('status', isEqualTo: 'pending').get();
          final waste = WasteEngine.evaluate(
            surplusId: s.id, foodType: s.foodType,
            expiryStatus: s.expiryStatus, quantity: s.quantity,
            timestamp: s.timestamp, nearbyRequestCount: reqSnap.docs.length,
            expiryTime: s.expiryTime,
          );
          if (waste != null) {
            await doc.reference.update({
              'status': waste.destination, 'wasteType': waste.destination,
              'autoRedirect': true, 'wasteReason': waste.reason.name,
            });
            redirected++;
          }
        }
      }
      // Auto-cancel stale requests
      final reqSnap = await _db.collection('requests')
          .where('status', isEqualTo: 'pending').get();
      for (final doc in reqSnap.docs) {
        final r = FoodRequest.fromFirestore(doc.id, doc.data());
        if (AutoStatusEngine.shouldAutoCancel(r)) {
          await doc.reference.update({'status': 'cancelled'});
          cancelled++;
        }
      }
    } catch (e) { debugPrint('[FS] sweep: $e'); }
    return {'expired': expired, 'redirected': redirected, 'cancelled': cancelled};
  }

  // ═══════════════════════════════════════════════════════════════════
  // REPORTS + MISC
  // ═══════════════════════════════════════════════════════════════════

  Future<void> submitReport({
    required ReportType reportType, required String description,
    String? imageUrl, String? listingId,
  }) async {
    final ref = _db.collection('user_reports').doc();
    await ref.set({
      'id': ref.id, 'userId': _uid, 'reportType': reportType.name,
      'description': description, 'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      if (imageUrl  != null) 'imageUrl':  imageUrl,
      if (listingId != null) 'listingId': listingId,
    });
  }

  Future<SearchResult> search(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return SearchResult(listings: sampleListings, surplusFood: []);
    final snap = await _db.collection('surplus_food')
        .where('status', isEqualTo: 'available').get();
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
          l.donorName.toLowerCase().contains(q)),
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

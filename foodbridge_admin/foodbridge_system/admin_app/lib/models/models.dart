// models.dart — FoodBridge Smart System
// Priority system + volunteer matching + delivery tracking + clean camelCase

import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────

enum ExpiryStatus  { fresh, nearExpiry, expired }
enum RequestStatus { pending, accepted, completed, cancelled }
enum TaskStatus    { available, accepted, inProgress, completed }
enum ReportType    { spoiledFood, incorrectLocation, notAvailable, other }
enum UserRole      { user, volunteer, admin }

/// Priority level — calculated automatically, stored in Firestore
enum Priority { high, medium, low }

// ─── Priority helpers ─────────────────────────────────────────────────────

extension PriorityExt on Priority {
  String get label {
    switch (this) {
      case Priority.high:   return 'High';
      case Priority.medium: return 'Medium';
      case Priority.low:    return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:   return const Color(0xFFD85A30);
      case Priority.medium: return const Color(0xFFE9A825);
      case Priority.low:    return const Color(0xFF40916C);
    }
  }

  Color get bg {
    switch (this) {
      case Priority.high:   return const Color(0xFFFAECE7);
      case Priority.medium: return const Color(0xFFFDF3D7);
      case Priority.low:    return const Color(0xFFD8F3DC);
    }
  }

  int get sortOrder {
    switch (this) {
      case Priority.high:   return 0;
      case Priority.medium: return 1;
      case Priority.low:    return 2;
    }
  }

  static Priority fromString(String? s) {
    switch (s) {
      case 'high':   return Priority.high;
      case 'low':    return Priority.low;
      default:       return Priority.medium;
    }
  }
}

/// Auto-calculate priority for surplus food.
/// High: near/expired OR > 50 portions
/// Low: fresh AND < 10 portions
/// Medium: everything else
Priority calcSurplusPriority(String expiryStatus, String quantity) {
  final isNearExpiry = expiryStatus == 'Near Expiry' || expiryStatus == 'Expired';
  final qty = _parseQty(quantity);
  if (isNearExpiry || qty > 50) return Priority.high;
  if (!isNearExpiry && qty < 10) return Priority.low;
  return Priority.medium;
}

/// Auto-calculate priority for requests.
/// High: pending > 30 min (urgent wait)
/// Low: pending < 5 min (just submitted)
Priority calcRequestPriority(DateTime timestamp, String? expiryStatus) {
  final age = DateTime.now().difference(timestamp).inMinutes;
  if (age > 30 || expiryStatus == 'Near Expiry' || expiryStatus == 'Expired') {
    return Priority.high;
  }
  if (age < 5) return Priority.low;
  return Priority.medium;
}

int _parseQty(String qty) {
  final match = RegExp(r'\d+').firstMatch(qty);
  return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
}

// ─── AppUser ──────────────────────────────────────────────────────────────
// Firestore: users/{uid}
// Fields: uid, email, name, role, lat, lng, isAvailable, createdAt

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String name;
  final double lat;         // volunteer location for matching
  final double lng;
  final bool isAvailable;  // volunteer not currently handling a task

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.lat = 12.9716,
    this.lng = 77.5946,
    this.isAvailable = true,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
    uid:         uid,
    email:       d['email']       as String? ?? '',
    name:        d['name']        as String? ?? 'User',
    role:        _roleFromString(d['role'] as String?),
    lat:         (d['lat'] as num?)?.toDouble()  ?? 12.9716,
    lng:         (d['lng'] as num?)?.toDouble()  ?? 77.5946,
    isAvailable: d['isAvailable'] as bool? ?? true,
  );

  static UserRole _roleFromString(String? s) {
    switch (s) {
      case 'volunteer': return UserRole.volunteer;
      case 'admin':     return UserRole.admin;
      default:          return UserRole.user;
    }
  }

  Map<String, dynamic> toMap() => {
    'uid':         uid,
    'email':       email,
    'name':        name,
    'role':        role.name,
    'lat':         lat,
    'lng':         lng,
    'isAvailable': isAvailable,
  };

  AppUser copyWith({
    String? uid, String? email, UserRole? role, String? name,
    double? lat, double? lng, bool? isAvailable,
  }) => AppUser(
    uid:         uid         ?? this.uid,
    email:       email       ?? this.email,
    role:        role        ?? this.role,
    name:        name        ?? this.name,
    lat:         lat         ?? this.lat,
    lng:         lng         ?? this.lng,
    isAvailable: isAvailable ?? this.isAvailable,
  );
}

// ─── SurplusFood ──────────────────────────────────────────────────────────
// Firestore: surplus_food/{id}
// Statuses: available → accepted → completed | expired
// NEW: priority field

class SurplusFood {
  final String id;
  final String createdBy;
  final String createdByName;
  final String foodType;
  final String description;
  final String quantity;
  final String location;
  final String expiryStatus;
  final DateTime preparedTime;
  final DateTime? expiryTime;
  final DateTime timestamp;
  final String status;
  final Priority priority;          // NEW
  final String? acceptedBy;
  final String? acceptedByName;
  final String? suggestedVolunteerId; // NEW — smart matching result
  final double lat;
  final double lng;
  final String imageEmoji;
  final String? disposalType;        // NEW: biogas | farmer | discard
  final DateTime? redirectedAt;     // NEW
  final String? suggestedAction;    // NEW: auto-calc suggestion

  const SurplusFood({
    required this.id,
    required this.createdBy,
    required this.createdByName,
    required this.foodType,
    required this.description,
    required this.quantity,
    required this.location,
    required this.expiryStatus,
    required this.preparedTime,
    this.expiryTime,
    required this.timestamp,
    required this.status,
    this.priority = Priority.medium,
    this.acceptedBy,
    this.acceptedByName,
    this.suggestedVolunteerId,
    this.lat = 12.9716,
    this.lng = 77.5946,
    this.imageEmoji = '🍱',
    this.disposalType,
    this.redirectedAt,
    this.suggestedAction,
  });

  factory SurplusFood.fromFirestore(String docId, Map<String, dynamic> d) {
    DateTime ts(dynamic v) {
      if (v == null) return DateTime.now();
      try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    return SurplusFood(
      id:                   docId,
      createdBy:            d['createdBy']            as String? ?? '',
      createdByName:        d['createdByName']        as String? ?? 'Unknown',
      foodType:             d['foodType']             as String? ?? '',
      description:          d['description']          as String? ?? '',
      quantity:             d['quantity']             as String? ?? '',
      location:             d['location']             as String? ?? '',
      expiryStatus:         d['expiryStatus']         as String? ?? 'Fresh',
      preparedTime:         ts(d['preparedTime'] ?? d['timestamp']),
      expiryTime:           d['expiryTime'] != null ? ts(d['expiryTime']) : null,
      timestamp:            ts(d['timestamp']),
      status:               d['status']               as String? ?? 'available',
      priority:             PriorityExt.fromString(d['priority'] as String?),
      acceptedBy:           d['acceptedBy']           as String?,
      acceptedByName:       d['acceptedByName']       as String?,
      suggestedVolunteerId: d['suggestedVolunteerId'] as String?,
      lat:                  (d['lat'] as num?)?.toDouble()  ?? 12.9716,
      lng:                  (d['lng'] as num?)?.toDouble()  ?? 77.5946,
      imageEmoji:           d['imageEmoji']           as String? ?? '🍱',
      disposalType:         d['disposalType']         as String?,
      redirectedAt:         d['redirectedAt'] != null ? ts(d['redirectedAt']) : null,
      suggestedAction:      d['suggestedAction']      as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id':             id,
    'createdBy':      createdBy,
    'createdByName':  createdByName,
    'foodType':       foodType,
    'description':    description,
    'quantity':       quantity,
    'location':       location,
    'expiryStatus':   expiryStatus,
    'preparedTime':   preparedTime.toIso8601String(),
    if (expiryTime != null) 'expiryTime': expiryTime!.toIso8601String(),
    'timestamp':      timestamp.toIso8601String(),
    'status':         status,
    'priority':       priority.name,
    if (acceptedBy           != null) 'acceptedBy':           acceptedBy,
    if (acceptedByName       != null) 'acceptedByName':       acceptedByName,
    if (suggestedVolunteerId != null) 'suggestedVolunteerId': suggestedVolunteerId,
    'lat':            lat,
    'lng':            lng,
    'imageEmoji':     imageEmoji,
    if (disposalType    != null) 'disposalType':    disposalType,
    if (redirectedAt    != null) 'redirectedAt':    redirectedAt!.toIso8601String(),
    if (suggestedAction != null) 'suggestedAction': suggestedAction,
  };

  FoodListing toFoodListing() {
    ExpiryStatus es;
    switch (expiryStatus) {
      case 'Near Expiry': es = ExpiryStatus.nearExpiry; break;
      case 'Expired':     es = ExpiryStatus.expired;    break;
      default:            es = ExpiryStatus.fresh;
    }
    return FoodListing(
      id: id, foodType: foodType, description: description,
      quantity: quantity, location: location, distanceKm: 0.0,
      expiryStatus: es, donorName: createdByName, donorType: 'Community',
      postedAt: timestamp, lat: lat, lng: lng, imageEmoji: imageEmoji,
      isSurplus: true, surplusId: id, priority: priority,
    );
  }
}

// ─── FoodListing ──────────────────────────────────────────────────────────
class FoodListing {
  final String id;
  final String foodType;
  final String description;
  final String quantity;
  final String location;
  final double distanceKm;
  final ExpiryStatus expiryStatus;
  final String donorName;
  final String donorType;
  final DateTime postedAt;
  final double lat;
  final double lng;
  final String imageEmoji;
  final bool isSurplus;
  final String surplusId;
  final Priority priority;   // NEW

  const FoodListing({
    required this.id,
    required this.foodType,
    required this.description,
    required this.quantity,
    required this.location,
    required this.distanceKm,
    required this.expiryStatus,
    required this.donorName,
    required this.donorType,
    required this.postedAt,
    required this.lat,
    required this.lng,
    this.imageEmoji = '🍱',
    this.isSurplus  = false,
    this.surplusId  = '',
    this.priority   = Priority.medium,
  });

  Color get statusColor {
    switch (expiryStatus) {
      case ExpiryStatus.fresh:      return const Color(0xFF40916C);
      case ExpiryStatus.nearExpiry: return const Color(0xFFE9A825);
      case ExpiryStatus.expired:    return const Color(0xFFD85A30);
    }
  }

  Color get statusBg {
    switch (expiryStatus) {
      case ExpiryStatus.fresh:      return const Color(0xFFD8F3DC);
      case ExpiryStatus.nearExpiry: return const Color(0xFFFDF3D7);
      case ExpiryStatus.expired:    return const Color(0xFFFAECE7);
    }
  }

  String get statusLabel {
    switch (expiryStatus) {
      case ExpiryStatus.fresh:      return 'Fresh';
      case ExpiryStatus.nearExpiry: return 'Near Expiry';
      case ExpiryStatus.expired:    return 'Expired';
    }
  }
}

// ─── FoodRequest ──────────────────────────────────────────────────────────
// Firestore: requests/{id}
// NEW: priority, suggestedVolunteerId, acceptedTime, lat, lng, locationArea

class FoodRequest {
  final String id;
  final String foodId;
  final String listingId;       // alias = foodId
  final String userId;
  final String foodType;
  final String location;
  final String quantity;
  final RequestStatus status;
  final DateTime timestamp;
  final DateTime requestedAt;   // alias = timestamp
  final Priority priority;      // NEW — auto-calculated
  final String? acceptedBy;
  final String? volunteerName;
  final DateTime? acceptedTime;   // NEW — for delivery tracking
  final DateTime? completedTime;
  final String? suggestedVolunteerId; // NEW — smart match suggestion
  final bool adminOverride;
  final double lat;             // NEW — request location for map
  final double lng;
  final String locationArea;   // NEW — area tag for grouping (e.g. "Indiranagar")

  const FoodRequest({
    required this.id,
    required this.foodId,
    required this.userId,
    required this.foodType,
    required this.location,
    required this.quantity,
    required this.status,
    required this.timestamp,
    this.priority             = Priority.medium,
    this.acceptedBy,
    this.volunteerName,
    this.acceptedTime,
    this.completedTime,
    this.suggestedVolunteerId,
    this.adminOverride        = false,
    this.lat                  = 12.9716,
    this.lng                  = 77.5946,
    this.locationArea         = '',
  })  : listingId   = foodId,
        requestedAt = timestamp;

  factory FoodRequest.fromFirestore(String docId, Map<String, dynamic> d) {
    DateTime ts(dynamic v) {
      if (v == null) return DateTime.now();
      try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    RequestStatus st(String? s) {
      switch (s) {
        case 'accepted':  return RequestStatus.accepted;
        case 'completed': return RequestStatus.completed;
        case 'cancelled': return RequestStatus.cancelled;
        default:          return RequestStatus.pending;
      }
    }
    return FoodRequest(
      id:                   docId,
      foodId:               d['foodId']               as String? ?? '',
      userId:               d['userId']               as String? ?? '',
      foodType:             d['foodType']             as String? ?? '',
      location:             d['location']             as String? ?? '',
      quantity:             d['quantity']             as String? ?? '',
      status:               st(d['status']            as String?),
      timestamp:            ts(d['timestamp']),
      priority:             PriorityExt.fromString(d['priority'] as String?),
      acceptedBy:           d['acceptedBy']           as String?,
      volunteerName:        d['volunteerName']        as String?,
      acceptedTime:         d['acceptedTime'] != null ? ts(d['acceptedTime']) : null,
      completedTime:        d['completedTime'] != null ? ts(d['completedTime']) : null,
      suggestedVolunteerId: d['suggestedVolunteerId'] as String?,
      adminOverride:        d['adminOverride']        as bool? ?? false,
      lat:                  (d['lat'] as num?)?.toDouble()  ?? 12.9716,
      lng:                  (d['lng'] as num?)?.toDouble()  ?? 77.5946,
      locationArea:         d['locationArea']         as String? ?? '',
    );
  }

  /// Clean camelCase only — no legacy snake_case duplicates
  Map<String, dynamic> toFirestore() => {
    'id':                   id,
    'foodId':               foodId,
    'userId':               userId,
    'foodType':             foodType,
    'location':             location,
    'quantity':             quantity,
    'status':               status.name,
    'timestamp':            timestamp.toIso8601String(),
    'priority':             priority.name,
    if (acceptedBy           != null) 'acceptedBy':           acceptedBy,
    if (volunteerName        != null) 'volunteerName':        volunteerName,
    if (acceptedTime         != null) 'acceptedTime':         acceptedTime!.toIso8601String(),
    if (completedTime        != null) 'completedTime':        completedTime!.toIso8601String(),
    if (suggestedVolunteerId != null) 'suggestedVolunteerId': suggestedVolunteerId,
    if (adminOverride)                'adminOverride':        true,
    'lat':                  lat,
    'lng':                  lng,
    'locationArea':         locationArea,
  };

  /// Delivery duration in minutes (null if not completed)
  int? get deliveryMinutes {
    if (acceptedTime == null || completedTime == null) return null;
    return completedTime!.difference(acceptedTime!).inMinutes;
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:   return const Color(0xFFE9A825);
      case RequestStatus.accepted:  return const Color(0xFF1A73E8);
      case RequestStatus.completed: return const Color(0xFF40916C);
      case RequestStatus.cancelled: return const Color(0xFFD85A30);
    }
  }

  Color get statusBg {
    switch (status) {
      case RequestStatus.pending:   return const Color(0xFFFDF3D7);
      case RequestStatus.accepted:  return const Color(0xFFE8F0FE);
      case RequestStatus.completed: return const Color(0xFFD8F3DC);
      case RequestStatus.cancelled: return const Color(0xFFFAECE7);
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:   return 'Pending';
      case RequestStatus.accepted:  return 'Accepted';
      case RequestStatus.completed: return 'Completed';
      case RequestStatus.cancelled: return 'Cancelled';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case RequestStatus.pending:   return Icons.schedule_outlined;
      case RequestStatus.accepted:  return Icons.check_circle_outline;
      case RequestStatus.completed: return Icons.task_alt_outlined;
      case RequestStatus.cancelled: return Icons.cancel_outlined;
    }
  }
}

// ─── VolunteerTask ────────────────────────────────────────────────────────
class VolunteerTask {
  final String id;
  final String foodType;
  final String pickupLocation;
  final String dropLocation;
  final String quantity;
  final TaskStatus status;
  final DateTime postedAt;
  final double distanceKm;
  final String urgency;
  final String emoji;
  final String requestId;
  final bool isSuggestedForMe;   // NEW — highlighted in volunteer view

  const VolunteerTask({
    required this.id,
    required this.foodType,
    required this.pickupLocation,
    required this.dropLocation,
    required this.quantity,
    required this.status,
    required this.postedAt,
    required this.distanceKm,
    required this.urgency,
    this.emoji             = '🚚',
    this.requestId         = '',
    this.isSuggestedForMe  = false,
  });

  Color get urgencyColor {
    switch (urgency) {
      case 'High':   return const Color(0xFFD85A30);
      case 'Medium': return const Color(0xFFE9A825);
      default:       return const Color(0xFF40916C);
    }
  }

  Color get urgencyBg {
    switch (urgency) {
      case 'High':   return const Color(0xFFFAECE7);
      case 'Medium': return const Color(0xFFFDF3D7);
      default:       return const Color(0xFFD8F3DC);
    }
  }
}

// ─── UserReport ───────────────────────────────────────────────────────────
class UserReport {
  final String id;
  final String userId;
  final ReportType reportType;
  final String description;
  final DateTime timestamp;
  final String status;

  const UserReport({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.description,
    required this.timestamp,
    this.status = 'pending',
  });

  factory UserReport.fromFirestore(String docId, Map<String, dynamic> d) {
    DateTime ts(dynamic v) {
      if (v == null) return DateTime.now();
      try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }
    ReportType rt(String? s) {
      switch (s) {
        case 'incorrectLocation': return ReportType.incorrectLocation;
        case 'notAvailable':      return ReportType.notAvailable;
        case 'spoiledFood':       return ReportType.spoiledFood;
        default:                  return ReportType.other;
      }
    }
    return UserReport(
      id: docId, userId: d['userId'] as String? ?? '',
      reportType: rt(d['reportType'] as String?),
      description: d['description'] as String? ?? '',
      timestamp: ts(d['timestamp']),
      status: d['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'reportType': reportType.name,
    'description': description, 'timestamp': timestamp.toIso8601String(),
    'status': status,
  };

  String get reportTypeLabel {
    switch (reportType) {
      case ReportType.spoiledFood:       return 'Spoiled / Unsafe Food';
      case ReportType.incorrectLocation: return 'Incorrect Location';
      case ReportType.notAvailable:      return 'Food Not Available';
      case ReportType.other:             return 'Other Issue';
    }
  }

  IconData get reportTypeIcon {
    switch (reportType) {
      case ReportType.spoiledFood:       return Icons.warning_amber_outlined;
      case ReportType.incorrectLocation: return Icons.location_off_outlined;
      case ReportType.notAvailable:      return Icons.no_food_outlined;
      case ReportType.other:             return Icons.help_outline_rounded;
    }
  }
}

// ─── AppNotification ──────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final IconData icon;
  final Color iconColor;

  const AppNotification({
    required this.id, required this.title, required this.body,
    required this.time, required this.icon, required this.iconColor,
    this.isRead = false,
  });
}

// ─── AdminStats — upgraded with delivery time + volunteer perf + location ─
class AdminStats {
  final int totalReports;
  final int activeRequests;
  final int completedDeliveries;
  final int activeVolunteers;
  final int expiredItems;
  final int pendingUserReports;
  final double avgDeliveryMinutes;         // NEW
  final int autoAssignedCount;             // NEW — smart matching
  final int manualAssignedCount;           // NEW
  final Map<String, int> requestsByArea;  // NEW — location grouping
  final List<VolunteerPerformance> volunteerPerformance; // NEW
  final int totalBiogas;         // NEW: W2R metrics
  final int totalFarmer;         // NEW: W2R metrics
  final int totalDiscarded;      // NEW: W2R metrics

  const AdminStats({
    this.totalReports        = 0,
    this.activeRequests      = 0,
    this.completedDeliveries = 0,
    this.activeVolunteers    = 0,
    this.expiredItems        = 0,
    this.pendingUserReports  = 0,
    this.avgDeliveryMinutes  = 0.0,
    this.autoAssignedCount   = 0,
    this.manualAssignedCount = 0,
    this.requestsByArea      = const {},
    this.volunteerPerformance = const [],
    this.totalBiogas         = 0,
    this.totalFarmer         = 0,
    this.totalDiscarded      = 0,
  });
}

/// Per-volunteer performance record
class VolunteerPerformance {
  final String volunteerId;
  final String volunteerName;
  final int tasksCompleted;
  final double avgDeliveryMinutes;

  const VolunteerPerformance({
    required this.volunteerId,
    required this.volunteerName,
    required this.tasksCompleted,
    required this.avgDeliveryMinutes,
  });
}

// ─── MatchResult — smart volunteer matching ───────────────────────────────
class MatchResult {
  final String volunteerId;
  final String volunteerName;
  final double distanceKm;
  final double score;  // lower = better

  const MatchResult({
    required this.volunteerId,
    required this.volunteerName,
    required this.distanceKm,
    required this.score,
  });
}

// ─── Static sample data ───────────────────────────────────────────────────

final List<FoodListing> sampleListings = [
  FoodListing(
    id: 'f1', foodType: 'Veg Biryani',
    description: 'Freshly cooked veg biryani. Made with basmati rice.',
    quantity: '25 portions', location: 'Indiranagar, 100ft Road',
    distanceKm: 0.8, expiryStatus: ExpiryStatus.fresh,
    donorName: 'Meghana Foods', donorType: 'Restaurant',
    postedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    lat: 12.9716, lng: 77.6412, imageEmoji: '🍛', priority: Priority.high,
  ),
  FoodListing(
    id: 'f2', foodType: 'Bread & Pastries',
    description: 'Assorted bread loaves, croissants, and muffins.',
    quantity: '40 pieces', location: 'Koramangala, 5th Block',
    distanceKm: 1.4, expiryStatus: ExpiryStatus.nearExpiry,
    donorName: 'Daily Bread Bakery', donorType: 'Restaurant',
    postedAt: DateTime.now().subtract(const Duration(hours: 1)),
    lat: 12.9352, lng: 77.6245, imageEmoji: '🥖', priority: Priority.high,
  ),
  FoodListing(
    id: 'f3', foodType: 'Dal & Rice Meals',
    description: 'Community kitchen lunch — dal tadka, rice, pickle.',
    quantity: '60 meal packs', location: 'Rajajinagar, Ward 22',
    distanceKm: 2.1, expiryStatus: ExpiryStatus.fresh,
    donorName: 'Seva Foundation', donorType: 'NGO',
    postedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    lat: 12.9916, lng: 77.5521, imageEmoji: '🍲', priority: Priority.medium,
  ),
];

final List<FoodRequest> sampleRequests = [
  FoodRequest(
    id: 'r1', foodId: 'f1', userId: 'demo_user',
    foodType: 'Veg Biryani', location: 'Indiranagar',
    status: RequestStatus.accepted, priority: Priority.high,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    acceptedTime: DateTime.now().subtract(const Duration(minutes: 50)),
    volunteerName: 'Arun Kumar', quantity: '5 portions',
    locationArea: 'Indiranagar',
  ),
  FoodRequest(
    id: 'r2', foodId: 'f3', userId: 'demo_user',
    foodType: 'Dal & Rice Meals', location: 'Rajajinagar',
    status: RequestStatus.pending, priority: Priority.medium,
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    quantity: '3 meal packs', locationArea: 'Rajajinagar',
  ),
];

final List<AppNotification> sampleNotifications = [
  AppNotification(
    id: 'n1', title: 'New food nearby!',
    body: 'Veg Biryani (HIGH priority) 0.8km away at Indiranagar.',
    time: DateTime.now().subtract(const Duration(minutes: 5)),
    icon: Icons.restaurant_outlined, iconColor: Color(0xFF40916C),
  ),
  AppNotification(
    id: 'n2', title: 'Request Accepted',
    body: 'Arun Kumar accepted your request. ETA 20 mins.',
    time: DateTime.now().subtract(const Duration(minutes: 45)),
    icon: Icons.check_circle_outline, iconColor: Color(0xFF1A73E8),
    isRead: true,
  ),
];

// models.dart — FoodBridge Unified System Model
// Contains all definitions for User, Volunteer, and Admin apps.
// All AI-computed fields included.

import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────

enum ExpiryStatus  { fresh, nearExpiry, expired }
enum RequestStatus { pending, accepted, completed, cancelled }
enum TaskStatus    { available, accepted, inProgress, completed }
enum ReportType    { spoiledFood, incorrectLocation, notAvailable, other }
enum UserRole      { user, volunteer, admin }
enum Priority      { high, medium, low }

/// Where food is automatically routed by the AI engine
enum AutoRoute { donation, delivery, biogas, feed }

/// Why food was redirected to waste management
enum WasteReason { expired, noRequestsLong, lowDemand }

/// AI-generated insight severity
enum InsightSeverity { info, warning, critical }

// ─── Extensions ───────────────────────────────────────────────────────────

extension PriorityExt on Priority {
  String get label { switch(this){case Priority.high:return'High';case Priority.medium:return'Medium';case Priority.low:return'Low';} }
  Color get color  { switch(this){case Priority.high:return const Color(0xFFD85A30);case Priority.medium:return const Color(0xFFE9A825);case Priority.low:return const Color(0xFF40916C);} }
  Color get bg     { switch(this){case Priority.high:return const Color(0xFFFAECE7);case Priority.medium:return const Color(0xFFFDF3D7);case Priority.low:return const Color(0xFFD8F3DC);} }
  int get sortOrder{ switch(this){case Priority.high:return 0;case Priority.medium:return 1;case Priority.low:return 2;} }
  static Priority fromString(String? s){ switch(s){case'high':return Priority.high;case'low':return Priority.low;default:return Priority.medium;} }
}

extension AutoRouteExt on AutoRoute {
  String get label { switch(this){case AutoRoute.donation:return'Donation';case AutoRoute.delivery:return'Delivery';case AutoRoute.biogas:return'Biogas';case AutoRoute.feed:return'Animal Feed';} }
  String get emoji { switch(this){case AutoRoute.donation:return'🤝';case AutoRoute.delivery:return'🚚';case AutoRoute.biogas:return'⚡';case AutoRoute.feed:return'🌾';} }
  Color get color  { switch(this){case AutoRoute.donation:return const Color(0xFF40916C);case AutoRoute.delivery:return const Color(0xFF1A73E8);case AutoRoute.biogas:return const Color(0xFF7B5EA7);case AutoRoute.feed:return const Color(0xFFE9A825);} }
  Color get bg     { switch(this){case AutoRoute.donation:return const Color(0xFFD8F3DC);case AutoRoute.delivery:return const Color(0xFFE8F0FE);case AutoRoute.biogas:return const Color(0xFFF0EBF8);case AutoRoute.feed:return const Color(0xFFFDF3D7);} }
  static AutoRoute fromString(String? s){ switch(s){case'donation':return AutoRoute.donation;case'biogas':return AutoRoute.biogas;case'feed':return AutoRoute.feed;default:return AutoRoute.delivery;} }
}

// ─── Priority engine (Internal Helpers) ───────────────────────────────────

(Priority, int) calcPriorityWithScore(
  String expiryStatus, String quantity,
  {DateTime? timestamp, DateTime? expiryTime}) {
  int score = 50;
  if (expiryStatus == 'Expired')        score += 40;
  else if (expiryStatus == 'Near Expiry') score += 25;
  if (expiryTime != null) {
    final mins = expiryTime.difference(DateTime.now()).inMinutes;
    if (mins < 60) score += 20; else if (mins < 180) score += 12; else if (mins < 360) score += 5;
  }
  final qty = _parseQty(quantity);
  if (qty > 80) score += 15; else if (qty > 40) score += 10; else if (qty < 5) score -= 10;
  if (timestamp != null) {
    final age = DateTime.now().difference(timestamp).inMinutes;
    if (age > 120) score += 15; else if (age > 60) score += 8; else if (age > 30) score += 3;
  }
  score = score.clamp(0, 100);
  final p = score >= 70 ? Priority.high : score >= 40 ? Priority.medium : Priority.low;
  return (p, score);
}

int _parseQty(String qty) {
  final match = RegExp(r'\d+').firstMatch(qty);
  return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
}

Priority calcSurplusPriority(String expiryStatus, String quantity) {
  final isNearExpiry = expiryStatus == 'Near Expiry' || expiryStatus == 'Expired';
  final qty = _parseQty(quantity);
  if (isNearExpiry || qty > 50) return Priority.high;
  if (!isNearExpiry && qty < 10) return Priority.low;
  return Priority.medium;
}

Priority calcRequestPriority(DateTime timestamp, String? expiryStatus) {
  final age = DateTime.now().difference(timestamp).inMinutes;
  if (age > 30 || expiryStatus == 'Near Expiry' || expiryStatus == 'Expired') {
    return Priority.high;
  }
  if (age < 5) return Priority.low;
  return Priority.medium;
}

// ─── AppUser ──────────────────────────────────────────────────────────────

class AppUser {
  final String uid;
  final String email;
  final UserRole role;
  final String name;
  final double lat;
  final double lng;
  final bool isAvailable;
  final double performanceScore; // AI: 0-100

  const AppUser({
    required this.uid, required this.email,
    required this.role, required this.name,
    this.lat = 12.9716, this.lng = 77.5946,
    this.isAvailable = true, this.performanceScore = 50.0,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
    uid: uid, email: d['email'] as String? ?? '',
    name: d['name'] as String? ?? 'User',
    role: _r(d['role'] as String?),
    lat: (d['lat'] as num?)?.toDouble() ?? 12.9716,
    lng: (d['lng'] as num?)?.toDouble() ?? 77.5946,
    isAvailable: d['isAvailable'] as bool? ?? true,
    performanceScore: (d['performanceScore'] as num?)?.toDouble() ?? 50.0,
  );
  static UserRole _r(String? s){ switch(s){case'volunteer':return UserRole.volunteer;case'admin':return UserRole.admin;default:return UserRole.user;} }

  Map<String, dynamic> toMap() => {
    'uid': uid,'email': email,'name': name,'role': role.name,
    'lat': lat,'lng': lng,'isAvailable': isAvailable,
    'performanceScore': performanceScore,
  };

  AppUser copyWith({
    String? uid, String? email, UserRole? role, String? name,
    double? lat, double? lng, bool? isAvailable, double? performanceScore,
  }) => AppUser(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    role: role ?? this.role,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    isAvailable: isAvailable ?? this.isAvailable,
    performanceScore: performanceScore ?? this.performanceScore,
  );
}


// ─── SurplusFood ──────────────────────────────────────────────────────────

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
  // AI fields
  final Priority priority;
  final int priorityScore;
  final AutoRoute autoRoute;
  final int routeConfidence;
  final String? suggestedVolunteerId;
  final String? assignedVolunteerId;
  final String? assignedVolunteerName;
  final String? matchedRequestId;
  final bool autoRedirect;
  final String? wasteType;
  final WasteReason? wasteReason;
  // Tracking
  final String? acceptedBy;
  final String? acceptedByName;
  final double lat;
  final double lng;
  final String imageEmoji;

  const SurplusFood({
    required this.id, required this.createdBy, required this.createdByName,
    required this.foodType, required this.description, required this.quantity,
    required this.location, required this.expiryStatus,
    required this.preparedTime, this.expiryTime,
    required this.timestamp, required this.status,
    this.priority = Priority.medium, this.priorityScore = 50,
    this.autoRoute = AutoRoute.delivery, this.routeConfidence = 0,
    this.suggestedVolunteerId, this.assignedVolunteerId,
    this.assignedVolunteerName, this.matchedRequestId,
    this.autoRedirect = false, this.wasteType, this.wasteReason,
    this.acceptedBy, this.acceptedByName,
    this.lat = 12.9716, this.lng = 77.5946, this.imageEmoji = '🍱',
  });

  factory SurplusFood.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime ts(dynamic v){if(v==null)return DateTime.now();try{return(v as dynamic).toDate()as DateTime;}catch(_){}if(v is String)return DateTime.tryParse(v)??DateTime.now();return DateTime.now();}
    WasteReason? wr(String? s){switch(s){case'expired':return WasteReason.expired;case'noRequestsLong':return WasteReason.noRequestsLong;case'lowDemand':return WasteReason.lowDemand;default:return null;}}
    return SurplusFood(
      id:id,createdBy:d['createdBy']as String? ?? '',createdByName:d['createdByName']as String? ??'Unknown',
      foodType:d['foodType']as String? ??'',description:d['description']as String? ??'',
      quantity:d['quantity']as String? ??'',location:d['location']as String? ??'',
      expiryStatus:d['expiryStatus']as String? ??'Fresh',
      preparedTime:ts(d['preparedTime']??d['timestamp']),
      expiryTime:d['expiryTime']!=null?ts(d['expiryTime']):null,
      timestamp:ts(d['timestamp']),status:d['status']as String? ??'available',
      priority:PriorityExt.fromString(d['priority']as String?),
      priorityScore:d['priorityScore']as int? ??50,
      autoRoute:AutoRouteExt.fromString(d['autoRoute']as String?),
      routeConfidence:d['routeConfidence']as int? ??0,
      suggestedVolunteerId:d['suggestedVolunteerId']as String?,
      assignedVolunteerId:d['assignedVolunteerId']as String?,
      assignedVolunteerName:d['assignedVolunteerName']as String?,
      matchedRequestId:d['matchedRequestId']as String?,
      autoRedirect:d['autoRedirect']as bool? ??false,
      wasteType:d['wasteType']as String?,wasteReason:wr(d['wasteReason']as String?),
      acceptedBy:d['acceptedBy']as String?,acceptedByName:d['acceptedByName']as String?,
      lat:(d['lat']as num?)?.toDouble()??12.9716,lng:(d['lng']as num?)?.toDouble()??77.5946,
      imageEmoji:d['imageEmoji']as String? ??'🍱',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id':id,'createdBy':createdBy,'createdByName':createdByName,
    'foodType':foodType,'description':description,'quantity':quantity,
    'location':location,'expiryStatus':expiryStatus,
    'preparedTime':preparedTime.toIso8601String(),
    if(expiryTime!=null)'expiryTime':expiryTime!.toIso8601String(),
    'timestamp':timestamp.toIso8601String(),'status':status,
    'priority':priority.name,'priorityScore':priorityScore,
    'autoRoute':autoRoute.name,'routeConfidence':routeConfidence,
    if(suggestedVolunteerId!=null)'suggestedVolunteerId':suggestedVolunteerId,
    if(assignedVolunteerId!=null)'assignedVolunteerId':assignedVolunteerId,
    if(assignedVolunteerName!=null)'assignedVolunteerName':assignedVolunteerName,
    if(matchedRequestId!=null)'matchedRequestId':matchedRequestId,
    if(autoRedirect)'autoRedirect':true,
    if(wasteType!=null)'wasteType':wasteType,
    if(wasteReason!=null)'wasteReason':wasteReason!.name,
    if(acceptedBy!=null)'acceptedBy':acceptedBy,
    if(acceptedByName!=null)'acceptedByName':acceptedByName,
    'lat':lat,'lng':lng,'imageEmoji':imageEmoji,
  };

  FoodListing toFoodListing(){
    ExpiryStatus es;
    switch(expiryStatus){case'Near Expiry':es=ExpiryStatus.nearExpiry;break;case'Expired':es=ExpiryStatus.expired;break;default:es=ExpiryStatus.fresh;}
    return FoodListing(
      id:id,foodType:foodType,description:description,quantity:quantity,
      location:location,distanceKm:0.0,expiryStatus:es,
      donorName:createdByName,donorType:'Community',postedAt:timestamp,
      lat:lat,lng:lng,imageEmoji:imageEmoji,isSurplus:true,surplusId:id,
      priority:priority,priorityScore:priorityScore,
      autoRoute:autoRoute,routeConfidence:routeConfidence,
      assignedVolunteerName:assignedVolunteerName,
      autoRedirect:autoRedirect,wasteType:wasteType,
    );
  }
}

// ─── FoodListing ──────────────────────────────────────────────────────────

class FoodListing {
  final String id,foodType,description,quantity,location,donorName,donorType,imageEmoji,surplusId;
  final double distanceKm,lat,lng;
  final ExpiryStatus expiryStatus;
  final DateTime postedAt;
  final bool isSurplus,autoRedirect;
  final Priority priority;
  final int priorityScore,routeConfidence;
  final AutoRoute autoRoute;
  final String? assignedVolunteerName,wasteType;

  const FoodListing({
    required this.id,required this.foodType,required this.description,
    required this.quantity,required this.location,required this.distanceKm,
    required this.expiryStatus,required this.donorName,required this.donorType,
    required this.postedAt,required this.lat,required this.lng,
    this.imageEmoji='🍱',this.isSurplus=false,this.surplusId='',
    this.priority=Priority.medium,this.priorityScore=50,
    this.autoRoute=AutoRoute.delivery,this.routeConfidence=0,
    this.assignedVolunteerName,this.autoRedirect=false,this.wasteType,
  });

  Color get statusColor{switch(expiryStatus){case ExpiryStatus.fresh:return const Color(0xFF40916C);case ExpiryStatus.nearExpiry:return const Color(0xFFE9A825);case ExpiryStatus.expired:return const Color(0xFFD85A30);}}
  Color get statusBg{switch(expiryStatus){case ExpiryStatus.fresh:return const Color(0xFFD8F3DC);case ExpiryStatus.nearExpiry:return const Color(0xFFFDF3D7);case ExpiryStatus.expired:return const Color(0xFFFAECE7);}}
  String get statusLabel{switch(expiryStatus){case ExpiryStatus.fresh:return'Fresh';case ExpiryStatus.nearExpiry:return'Near Expiry';case ExpiryStatus.expired:return'Expired';}}
}

// ─── FoodRequest ──────────────────────────────────────────────────────────

class FoodRequest {
  final String id,foodId,userId,foodType,location,quantity,locationArea;
  final RequestStatus status;
  final DateTime timestamp;
  final Priority priority;
  final int priorityScore;
  final String? acceptedBy,volunteerName,suggestedVolunteerId,assignedVolunteerId,matchedFoodId;
  final DateTime? acceptedTime,completedTime;
  final bool adminOverride;
  final int matchConfidence;
  final double lat,lng;

  const FoodRequest({
    required this.id,required this.foodId,required this.userId,
    required this.foodType,required this.location,required this.quantity,
    required this.status,required this.timestamp,
    this.priority=Priority.medium,this.priorityScore=50,
    this.acceptedBy,this.volunteerName,this.suggestedVolunteerId,
    this.assignedVolunteerId,this.matchedFoodId,
    this.acceptedTime,this.completedTime,
    this.matchConfidence=0,
    this.adminOverride=false,this.lat=12.9716,this.lng=77.5946,this.locationArea='',
  });

  factory FoodRequest.fromFirestore(String id, Map<String, dynamic> d){
    DateTime ts(dynamic v){if(v==null)return DateTime.now();try{return(v as dynamic).toDate()as DateTime;}catch(_){}if(v is String)return DateTime.tryParse(v)??DateTime.now();return DateTime.now();}
    RequestStatus st(String? s){switch(s){case'accepted':return RequestStatus.accepted;case'completed':return RequestStatus.completed;case'cancelled':return RequestStatus.cancelled;default:return RequestStatus.pending;}}
    return FoodRequest(
      id:id,foodId:d['foodId']as String? ??'',userId:d['userId']as String? ??'',
      foodType:d['foodType']as String? ??'',location:d['location']as String? ??'',
      quantity:d['quantity']as String? ??'',status:st(d['status']as String?),
      timestamp:ts(d['timestamp']),
      priority:PriorityExt.fromString(d['priority']as String?),
      priorityScore:d['priorityScore']as int? ??50,
      acceptedBy:d['acceptedBy']as String?,volunteerName:d['volunteerName']as String?,
      suggestedVolunteerId:d['suggestedVolunteerId']as String?,
      assignedVolunteerId:d['assignedVolunteerId']as String?,
      matchedFoodId:d['matchedFoodId']as String?,
      acceptedTime:d['acceptedTime']!=null?ts(d['acceptedTime']):null,
      completedTime:d['completedTime']!=null?ts(d['completedTime']):null,
      matchConfidence:d['matchConfidence']as int? ??0,
      adminOverride:d['adminOverride']as bool? ??false,
      lat:(d['lat']as num?)?.toDouble()??12.9716,lng:(d['lng']as num?)?.toDouble()??77.5946,
      locationArea:d['locationArea']as String? ??'',
    );
  }

  Map<String,dynamic> toFirestore()=>{
    'id':id,'foodId':foodId,'userId':userId,'foodType':foodType,
    'location':location,'quantity':quantity,'status':status.name,
    'timestamp':timestamp.toIso8601String(),
    'priority':priority.name,'priorityScore':priorityScore,
    if(acceptedBy!=null)'acceptedBy':acceptedBy,
    if(volunteerName!=null)'volunteerName':volunteerName,
    if(suggestedVolunteerId!=null)'suggestedVolunteerId':suggestedVolunteerId,
    if(assignedVolunteerId!=null)'assignedVolunteerId':assignedVolunteerId,
    if(matchedFoodId!=null)'matchedFoodId':matchedFoodId,
    if(acceptedTime!=null)'acceptedTime':acceptedTime!.toIso8601String(),
    if(completedTime!=null)'completedTime':completedTime!.toIso8601String(),
    if(matchConfidence>0)'matchConfidence':matchConfidence,
    if(adminOverride)'adminOverride':true,
    'lat':lat,'lng':lng,'locationArea':locationArea,
  };

  int? get deliveryMinutes{if(acceptedTime==null||completedTime==null)return null;return completedTime!.difference(acceptedTime!).inMinutes;}

  Color get statusColor{switch(status){case RequestStatus.pending:return const Color(0xFFE9A825);case RequestStatus.accepted:return const Color(0xFF1A73E8);case RequestStatus.completed:return const Color(0xFF40916C);case RequestStatus.cancelled:return const Color(0xFFD85A30);}}
  Color get statusBg{switch(status){case RequestStatus.pending:return const Color(0xFFFDF3D7);case RequestStatus.accepted:return const Color(0xFFE8F0FE);case RequestStatus.completed:return const Color(0xFFD8F3DC);case RequestStatus.cancelled:return const Color(0xFFFAECE7);}}
  String get statusLabel{switch(status){case RequestStatus.pending:return'Pending';case RequestStatus.accepted:return'Accepted';case RequestStatus.completed:return'Completed';case RequestStatus.cancelled:return'Cancelled';}}
  IconData get statusIcon{switch(status){case RequestStatus.pending:return Icons.schedule_outlined;case RequestStatus.accepted:return Icons.check_circle_outline;case RequestStatus.completed:return Icons.task_alt_outlined;case RequestStatus.cancelled:return Icons.cancel_outlined;}}

  DateTime get requestedAt => timestamp;
  String get listingId => foodId;
}

// ─── AI Types ─────────────────────────────────────────────────────────────

class AiInsight {
  final String id,message;
  final InsightSeverity severity;
  final IconData icon;
  final String? actionLabel;
  final DateTime generatedAt;

  const AiInsight({
    required this.id,
    required this.message,
    required this.severity,
    required this.icon,
    this.actionLabel,
    required this.generatedAt,
  });

  Color get color{switch(severity){case InsightSeverity.info:return const Color(0xFF1A73E8);case InsightSeverity.warning:return const Color(0xFFE9A825);case InsightSeverity.critical:return const Color(0xFFD85A30);}}
  Color get bg{switch(severity){case InsightSeverity.info:return const Color(0xFFE8F0FE);case InsightSeverity.warning:return const Color(0xFFFDF3D7);case InsightSeverity.critical:return const Color(0xFFFAECE7);}}
}

class AdminStats {
  final int totalReports,activeRequests,completedDeliveries,activeVolunteers;
  final int expiredItems,pendingUserReports,autoAssignedCount,manualAssignedCount;
  final int wasteRedirectedCount,foodSavedCount;
  final int totalBiogas, totalFarmer, totalDiscarded;
  final double avgDeliveryMinutes;
  final Map<String,int> requestsByArea;
  final List<VolunteerPerformance> volunteerPerformance;
  final List<AiInsight> aiInsights;

  const AdminStats({
    this.totalReports=0,this.activeRequests=0,this.completedDeliveries=0,
    this.activeVolunteers=0,this.expiredItems=0,this.pendingUserReports=0,
    this.autoAssignedCount=0,this.manualAssignedCount=0,
    this.wasteRedirectedCount=0,this.foodSavedCount=0,
    this.totalBiogas=0, this.totalFarmer=0, this.totalDiscarded=0,
    this.avgDeliveryMinutes=0.0,
    this.requestsByArea=const{},this.volunteerPerformance=const[],
    this.aiInsights=const[],
  });

  AdminStats copyWith({
    int? totalReports, activeRequests, completedDeliveries, activeVolunteers,
    int? expiredItems, pendingUserReports, autoAssignedCount, manualAssignedCount,
    int? wasteRedirectedCount, foodSavedCount,
    int? totalBiogas, totalFarmer, totalDiscarded,
    double? avgDeliveryMinutes,
    Map<String,int>? requestsByArea,
    List<VolunteerPerformance>? volunteerPerformance,
    List<AiInsight>? aiInsights,
  }) => AdminStats(
    totalReports: totalReports ?? this.totalReports,
    activeRequests: activeRequests ?? this.activeRequests,
    completedDeliveries: completedDeliveries ?? this.completedDeliveries,
    activeVolunteers: activeVolunteers ?? this.activeVolunteers,
    expiredItems: expiredItems ?? this.expiredItems,
    pendingUserReports: pendingUserReports ?? this.pendingUserReports,
    autoAssignedCount: autoAssignedCount ?? this.autoAssignedCount,
    manualAssignedCount: manualAssignedCount ?? this.manualAssignedCount,
    wasteRedirectedCount: wasteRedirectedCount ?? this.wasteRedirectedCount,
    foodSavedCount: foodSavedCount ?? this.foodSavedCount,
    totalBiogas: totalBiogas ?? this.totalBiogas,
    totalFarmer: totalFarmer ?? this.totalFarmer,
    totalDiscarded: totalDiscarded ?? this.totalDiscarded,
    avgDeliveryMinutes: avgDeliveryMinutes ?? this.avgDeliveryMinutes,
    requestsByArea: requestsByArea ?? this.requestsByArea,
    volunteerPerformance: volunteerPerformance ?? this.volunteerPerformance,
    aiInsights: aiInsights ?? this.aiInsights,
  );
}

class VolunteerPerformance {
  final String volunteerId,volunteerName;
  final int tasksCompleted;
  final double avgDeliveryMinutes,performanceScore;

  const VolunteerPerformance({
    required this.volunteerId,
    required this.volunteerName,
    required this.tasksCompleted,
    required this.avgDeliveryMinutes,
    this.performanceScore=0.0,
  });
}

class UserReport {
  final String id,userId,description,status;
  final ReportType reportType;
  final DateTime timestamp;

  const UserReport({
    required this.id,required this.userId,required this.reportType,
    required this.description,required this.timestamp,this.status='pending',
  });

  factory UserReport.fromFirestore(String id, Map<String, dynamic> d) {
    DateTime ts(dynamic v){if(v==null)return DateTime.now();try{return(v as dynamic).toDate()as DateTime;}catch(_){}if(v is String)return DateTime.tryParse(v)??DateTime.now();return DateTime.now();}
    ReportType rt(String? s){switch(s){case'incorrectLocation':return ReportType.incorrectLocation;case'notAvailable':return ReportType.notAvailable;case'spoiledFood':return ReportType.spoiledFood;default:return ReportType.other;}}
    return UserReport(
      id:id,userId:d['userId']as String? ??'',reportType:rt(d['reportType'] as String?),
      description:d['description']as String? ??'',timestamp:ts(d['timestamp']),
      status:d['status']as String? ??'pending',
    );
  }

  IconData get reportTypeIcon {
    switch (reportType) {
      case ReportType.spoiledFood: return Icons.no_food_outlined;
      case ReportType.incorrectLocation: return Icons.location_off_outlined;
      case ReportType.notAvailable: return Icons.event_busy_outlined;
      default: return Icons.flag_outlined;
    }
  }
  String get reportTypeLabel {
    switch (reportType) {
      case ReportType.spoiledFood: return 'Spoiled Food';
      case ReportType.incorrectLocation: return 'Incorrect Location';
      case ReportType.notAvailable: return 'No Longer Available';
      default: return 'Other Issue';
    }
  }
}

class AppNotification {
  final String id,title,body;
  final DateTime time;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  const AppNotification({required this.id,required this.title,required this.body,required this.time,required this.icon,required this.iconColor,this.isRead=false});
}

// ─── VolunteerTask (Legacy Support) ────────────────────────────────────────

class VolunteerTask {
  final String id,foodType,pickupLocation,dropLocation,quantity,urgency,emoji,requestId;
  final TaskStatus status;
  final DateTime postedAt;
  final double distanceKm;
  final bool isSuggestedForMe;

  const VolunteerTask({
    required this.id,required this.foodType,required this.pickupLocation,
    required this.dropLocation,required this.quantity,required this.status,
    required this.postedAt,required this.distanceKm,required this.urgency,
    this.emoji='🚚',this.requestId='',this.isSuggestedForMe=false,
  });
}

// ─── Static sample data ───────────────────────────────────────────────────

final List<FoodListing> sampleListings = [
  FoodListing(id:'f1',foodType:'Veg Biryani',description:'Freshly cooked veg biryani.',quantity:'25 portions',location:'Indiranagar, 100ft Road',distanceKm:0.8,expiryStatus:ExpiryStatus.fresh,donorName:'Meghana Foods',donorType:'Restaurant',postedAt:DateTime.now().subtract(const Duration(minutes:20)),lat:12.9716,lng:77.6412,imageEmoji:'🍛',priority:Priority.high,priorityScore:78,autoRoute:AutoRoute.donation,routeConfidence:87),
  FoodListing(id:'f2',foodType:'Bread & Pastries',description:'Assorted bread loaves.',quantity:'40 pieces',location:'Koramangala, 5th Block',distanceKm:1.4,expiryStatus:ExpiryStatus.nearExpiry,donorName:'Daily Bread Bakery',donorType:'Restaurant',postedAt:DateTime.now().subtract(const Duration(hours:1)),lat:12.9352,lng:77.6245,imageEmoji:'🥖',priority:Priority.high,priorityScore:82,autoRoute:AutoRoute.delivery,routeConfidence:91,assignedVolunteerName:'Arun Kumar'),
];

final List<AppNotification> sampleNotifications = [
  AppNotification(id:'n1',title:'🤖 AI auto-assigned Arun Kumar',body:'Veg Biryani delivery assigned automatically.',time:DateTime.now().subtract(const Duration(minutes:5)),icon:Icons.auto_awesome_outlined,iconColor:Color(0xFF40916C)),
];

final List<FoodRequest> sampleRequests = [
  FoodRequest(id:'r1',foodId:'f1',userId:'demo_user',foodType:'Veg Biryani',location:'Indiranagar',status:RequestStatus.accepted,priority:Priority.high,timestamp:DateTime.now().subtract(const Duration(hours:1)),acceptedTime:DateTime.now().subtract(const Duration(minutes:50)),volunteerName:'Arun Kumar',quantity:'5 portions',locationArea:'Indiranagar'),
];

# FoodBridge — Full System Setup Guide
## User App + Admin App + Shared Firebase Backend

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  Firebase Project                        │
│            foodbridge-rohan-9cb08                       │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  surplus_food│  │   requests   │  │ user_reports │  │
│  │   (stream)   │  │   (stream)   │  │   (stream)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│  ┌──────────────┐                                        │
│  │    users     │                                        │
│  │(roles:auth)  │                                        │
│  └──────────────┘                                        │
└─────────────────────────────────────────────────────────┘
         ▲                ▲                  ▲
         │                │                  │
  ┌──────┴──────┐  ┌──────┴──────┐  ┌───────┴──────┐
  │  User App   │  │ Volunteer   │  │  Admin App   │
  │  (role=user)│  │(role=volun.)│  │ (role=admin) │
  └─────────────┘  └─────────────┘  └──────────────┘
  Note: Volunteer view is INSIDE the User App (role-based nav)
```

---

## Real-Time Data Flow

```
USER reports surplus food
  → surplus_food/{id}  status: 'available'
  → listingsStream() fires → Home Screen + Map update instantly

USER requests food
  → requests/{id}  status: 'pending'
  → activeTasksStream() fires → Volunteer task list updates instantly
  → allRequestsStream() fires → Admin dashboard updates instantly

VOLUNTEER accepts task  (atomic transaction - race-condition safe)
  → requests/{id}  status: 'accepted', acceptedBy: volunteerId
  → userRequestsStream() fires → User's request status updates instantly
  → Admin activity feed updates instantly

VOLUNTEER marks done
  → requests/{id}  status: 'completed', completedTime: serverTimestamp
  → completedRequestsStream() fires → Volunteer Completed tab updates
  → User sees 'Completed' status instantly
  → Admin stats update instantly

ADMIN expires food
  → surplus_food/{id}  status: 'expired'
  → listingsStream() fires → Removed from all user feeds instantly

ADMIN force-completes request
  → requests/{id}  status: 'completed', adminOverride: true
  → All streams update across all apps instantly
```

---

## Step 1 — Firebase Project Setup

You already have: **foodbridge-rohan-9cb08**

### Enable in Firebase Console:
1. **Authentication** → Sign-in method → Email/Password → Enable
2. **Firestore** → Create database → Production mode → `asia-south1`

---

## Step 2 — Deploy Security Rules & Indexes

```bash
# From the project root (where firestore.rules is)
firebase login
firebase use foodbridge-rohan-9cb08

# Deploy rules
firebase deploy --only firestore:rules

# Deploy indexes (required for compound queries)
firebase deploy --only firestore:indexes
```

---

## Step 3 — User App Setup

Your User App already has `firebase_options.dart` configured. ✅

```bash
cd foodbridge_user

# Replace these files with the updated versions:
# lib/models/models.dart          (admin role + serialization upgrade)
# lib/services/firebase_service.dart  (atomic acceptTask, admin streams)
# lib/services/auth_service.dart  (admin role support)
# lib/services/app_state.dart     (isAdmin getter)
# lib/main.dart                   (admin role guard in nav)

flutter pub get
flutter run -d chrome
```

---

## Step 4 — Admin App Setup

The Admin App is a **separate Flutter project** in `foodbridge_admin/`.

```bash
cd foodbridge_admin

# Copy firebase_options.dart from user app (same Firebase project)
cp ../foodbridge_user/lib/firebase_options.dart lib/

flutter pub get
flutter run -d chrome    # or -d android
```

---

## Step 5 — Create Admin Account

### Option A — Firebase Console (recommended)
1. Firebase Console → Authentication → Add user
2. Note the UID
3. Firestore → users → New document → ID = UID
4. Add fields: `email`, `name`, `role: "admin"`, `uid`

### Option B — From Admin App
Register once, then manually set `role: "admin"` in Firestore Console.

---

## Step 6 — Test the Full Flow

| Action | App | Expected result |
|---|---|---|
| Register as User | User App | Login → Home screen |
| Register as Volunteer | User App | Login → Volunteer tab |
| Report surplus food | User App (Home) | Appears on Home + Map instantly |
| Request food | User App | Appears in Volunteer tasks instantly |
| Accept task | User App (Volunteer tab) | Mark Done button appears |
| Mark Done | User App (Volunteer tab) | Moves to Completed tab |
| Login as Admin | Admin App | Dashboard with live stats |
| Mark item expired | Admin App | Removed from user feeds |
| Force complete | Admin App | Request marked done everywhere |
| Resolve report | Admin App | Moves to Resolved tab |

---

## Firestore Collections Schema

### users/{uid}
```json
{
  "uid":       "firebase_auth_uid",
  "email":     "user@example.com",
  "name":      "Rohan Kumar",
  "role":      "user | volunteer | admin",
  "createdAt": "<server timestamp>"
}
```

### surplus_food/{id}
```json
{
  "id":             "auto-id",
  "createdBy":      "uid",
  "createdByName":  "Rohan Kumar",
  "foodType":       "Veg Biryani",
  "description":    "Freshly cooked...",
  "quantity":       "25 portions",
  "location":       "Indiranagar",
  "expiryStatus":   "Fresh | Near Expiry | Expired",
  "preparedTime":   "<timestamp>",
  "expiryTime":     "<timestamp> (optional)",
  "timestamp":      "<server timestamp>",
  "status":         "available | accepted | completed | expired",
  "acceptedBy":     "volunteerId (when accepted)",
  "acceptedByName": "Volunteer Name",
  "lat":            12.9716,
  "lng":            77.5946,
  "imageEmoji":     "🍛"
}
```

### requests/{id}
```json
{
  "id":            "auto-id",
  "foodId":        "surplus_food doc id",
  "userId":        "requestor uid",
  "foodType":      "Veg Biryani",
  "location":      "Indiranagar",
  "quantity":      "5 portions",
  "status":        "pending | accepted | completed | cancelled",
  "timestamp":     "<server timestamp>",
  "acceptedBy":    "volunteerId",
  "volunteerName": "Volunteer Name",
  "completedTime": "<server timestamp>",
  "adminOverride": true
}
```

### user_reports/{id}
```json
{
  "id":          "auto-id",
  "userId":      "uid",
  "reportType":  "spoiledFood | incorrectLocation | notAvailable | other",
  "description": "The food smelled bad...",
  "timestamp":   "<server timestamp>",
  "status":      "pending | resolved",
  "imageUrl":    "optional",
  "listingId":   "optional"
}
```

---

## Security Model

| Collection | User (read) | User (write) | Volunteer | Admin |
|---|---|---|---|---|
| users | Own only | Own only | Own only | All |
| surplus_food | All available | Create own | Update status | Full control |
| requests | Own only | Create own | Read all, update status | Full control |
| user_reports | Own only | Create own | — | Full control |

---

## Key Technical Decisions

**Atomic Accept Transaction**
`acceptTask()` uses `_db.runTransaction()` — if two volunteers tap Accept simultaneously, only one succeeds. The loser gets "Task already accepted by someone else."

**Merged Stream for Volunteer**
`activeTasksStream()` merges `pending` (all) + `accepted` (own volunteer's) so the "Mark Done" button stays visible after accepting. Without this, the card disappears immediately after Accept.

**Admin Stats Stream**
`adminStatsStream()` subscribes to all 4 collections simultaneously. Any change in any collection recomputes and emits updated `AdminStats` within milliseconds.

**No orderBy + completedTime**
`completedRequestsStream()` avoids `orderBy('completedTime')` to skip needing a composite Firestore index. Sorting happens client-side.

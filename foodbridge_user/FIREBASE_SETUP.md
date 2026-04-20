# FoodBridge — User App · Firebase Setup Guide

## What's implemented in this patch

| Feature | File | How |
|---|---|---|
| Firebase Auth (email/password) | `auth_service.dart` | `signIn` / `register` / `signOut` |
| Role-based login | `login_screen.dart` | User / Volunteer chip selector |
| Role-based navigation | `main.dart` | Different bottom nav per role |
| Real-time food listings | `home_screen.dart` | `StreamBuilder` on `surplus_food` |
| Surplus food → Home | `firebase_service.dart` | `listingsStream()` merges live + static |
| Map with live markers | `map_screen.dart` | `StreamBuilder` + fixed tap coords |
| End-to-end request flow | `firebase_service.dart` | `createRequest()` → Firestore `requests/` |
| Volunteer task feed | `volunteer_screen.dart` | `StreamBuilder` on `pendingRequestsStream()` |
| Accept task | `volunteer_screen.dart` | `acceptTask()` → status = accepted |
| Complete task | `volunteer_screen.dart` | `completeTask()` → status = completed |
| Completed tasks section | `volunteer_screen.dart` | `VolunteerCompletedScreen` stream |
| User requests stream | `requests_screen.dart` | `userRequestsStream()` |
| Firestore security rules | `firestore.rules` | Role-enforced read/write |
| Firestore indexes | `firestore.indexes.json` | For compound queries |

---

## Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `foodbridge`
3. Enable **Google Analytics** (optional)

---

## Step 2 — Enable Firebase Services

### Authentication
1. Firebase Console → **Authentication** → Get started
2. Sign-in method → **Email/Password** → Enable → Save

### Firestore Database
1. Firebase Console → **Firestore Database** → Create database
2. Select **Start in production mode**
3. Choose region: `asia-south1` (Mumbai — closest to Bengaluru)

---

## Step 3 — Connect Flutter to Firebase

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In your Flutter project root:
cd foodbridge_user

# Configure (auto-creates google-services.json + GoogleService-Info.plist)
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID

# Install packages
flutter pub get
```

---

## Step 4 — Activate Firebase in main.dart

Open `lib/main.dart` and make these two changes:

```dart
// 1. Uncomment at the top:
import 'firebase_options.dart';

// 2. In main(), replace:
await Firebase.initializeApp();
// With:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Step 5 — Deploy Security Rules and Indexes

```bash
# From project root (where firestore.rules and firestore.indexes.json are)
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## Step 6 — Run the App

```bash
flutter run -d chrome      # web
flutter run -d android     # Android
flutter run -d windows     # Windows
```

---

## Firestore Data Flow

```
User reports surplus food
        │
        ▼
  surplus_food/{id}        ← status: "available"
        │
        │  listingsStream() merges this into Home Screen + Map
        │
        ▼
  User taps "Request Food"
        │
        ▼
    requests/{id}           ← status: "pending", foodId, userId, timestamp
        │
        │  pendingRequestsStream() shows this to all volunteers
        │
        ▼
  Volunteer taps "Accept Task"
        │
        ▼
    requests/{id}           ← status: "accepted", acceptedBy: volunteerId
        │
        │  acceptedRequestsStream() shows to this volunteer
        │  userRequestsStream() updates User's "My Requests" tab
        │
        ▼
  Volunteer taps "Mark Done"
        │
        ▼
    requests/{id}           ← status: "completed", completedTime: timestamp
        │
        │  completedRequestsStream() shows in Volunteer "Completed" tab
        │  userRequestsStream() updates User "Completed" tab
```

---

## Test Accounts (create in Firebase Auth console or via app)

| Email | Password | Role |
|---|---|---|
| user@test.com | test123 | user |
| volunteer@test.com | test123 | volunteer |

---

## Firestore Collections Schema

### `users/{uid}`
```json
{
  "uid": "abc123",
  "email": "user@test.com",
  "name": "Rohan",
  "role": "user",
  "createdAt": "<timestamp>"
}
```

### `surplus_food/{id}`
```json
{
  "id": "auto-id",
  "createdBy": "uid",
  "createdByName": "Rohan",
  "foodType": "Veg Biryani",
  "description": "Freshly cooked",
  "quantity": "20 portions",
  "location": "Indiranagar",
  "expiryStatus": "Fresh",
  "preparedTime": "<timestamp>",
  "expiryTime": "<timestamp>",
  "timestamp": "<timestamp>",
  "status": "available",
  "lat": 12.9716,
  "lng": 77.5946,
  "imageEmoji": "🍛"
}
```

### `requests/{id}`
```json
{
  "id": "auto-id",
  "foodId": "surplus_food doc id",
  "food_id": "same (alias)",
  "userId": "uid",
  "foodType": "Veg Biryani",
  "location": "Indiranagar",
  "quantity": "5 portions",
  "status": "pending",
  "timestamp": "<timestamp>",
  "acceptedBy": "volunteer uid (when accepted)",
  "volunteerName": "Arun Kumar (when accepted)",
  "completedTime": "<timestamp> (when completed)"
}
```

### `user_reports/{id}`
```json
{
  "id": "auto-id",
  "userId": "uid",
  "reportType": "spoiledFood",
  "description": "The food smelled bad",
  "timestamp": "<timestamp>",
  "status": "pending",
  "imageUrl": "optional",
  "listingId": "optional"
}
```

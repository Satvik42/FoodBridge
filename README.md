# FoodBridge - Food Rescue and Redistribution Platform

## Vertical
**Social Impact & Sustainability**

FoodBridge is a community-driven platform designed to reduce food waste and combat hunger by connecting food donors, volunteers, and those in need.

## Approach and Logic
The platform is built on a tripartite ecosystem:
1. **Donors (Users):** Individuals or businesses with surplus food can quickly post details about available items, including quantity, type, and location.
2. **Volunteers:** Community members who receive real-time notifications of donation tasks. They facilitate the physical transfer of food from donors to recipients or community fridges.
3. **Admins:** Oversee the entire operation, manage reports, track surplus data, and ensure the platform's integrity through a dedicated dashboard.

The logic follows a "Request-Fulfillment" model where every donation or request is tracked through states (Pending, Active, Completed), ensuring accountability and transparency.

## How the Solution Works
- **Cross-Platform Accessibility:** Built with Flutter, providing a seamless experience across Android, iOS, and Web.
- **Real-time Backend:** Powered by Firebase (Firestore, Auth, and Storage) for instant synchronization of donation tasks and user data.
- **Role-Based Access Control:** A single codebase handles multiple user roles, presenting a tailored UI for regular users, volunteers, and administrators.
- **Interactive Mapping:** Helps users and volunteers locate nearby food donations and requests efficiently.
- **Admin Dashboard:** A separate Flutter Web application for high-level management and data analysis.

## Assumptions Made
- **Firebase Configuration:** The project assumes a valid Firebase project is set up. The `firebase_options.dart` files contain the necessary configuration.
- **Connectivity:** Users are assumed to have stable internet connectivity for real-time updates via Firestore.
- **Location Services:** The mapping feature assumes users grant permission for GPS/Location services.

## Getting Started

### Prerequisites
- Flutter SDK (latest version recommended)
- Dart SDK
- A Firebase project

### Installation

1. **Clone the project:**
   ```bash
   git clone https://github.com/Satvik42/FoodBridge.git
   cd FoodBridge
   ```

2. **Setup User App:**
   ```bash
   cd foodbridge_user
   flutter pub get
   ```

3. **Setup Admin App:**
   ```bash
   cd foodbridge_admin/foodbridge_system/admin_app
   flutter pub get
   ```

### Running the Application

#### User App
To run the mobile app (or web version):
```bash
cd foodbridge_user
flutter run
```

#### Admin App
To run the admin dashboard (Web):
```bash
cd foodbridge_admin/foodbridge_system/admin_app
flutter run -d chrome
```

---
*Developed with ❤️ for a Zero-Waste Future.*

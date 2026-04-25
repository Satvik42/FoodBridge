# FoodBridge - Food Rescue and Redistribution Platform

## Vertical
**Social Impact & Sustainability (Google Solutions Challenge 2026)**

FoodBridge is an intelligent, community-driven platform designed to reduce food waste and combat hunger by connecting food donors, volunteers, and those in need. It directly targets **SDG 2 (Zero Hunger)** and **SDG 12 (Responsible Consumption and Production)**.

## Approach and Logic
The platform is built on a tripartite ecosystem that operates from a **single, unified codebase**:
1. **Donors (Users):** Individuals or businesses with surplus food can quickly post details about available items, including quantity, type, and location.
2. **Volunteers:** Community members who receive real-time, AI-prioritized notifications of donation tasks. They facilitate the physical transfer of food from donors to recipients.
3. **Admins:** Oversee the entire operation, manage reports, track surplus data, and ensure the platform's integrity through a dedicated, role-based dashboard built right into the app.

## How the Solution Works
- **Waste-to-Resource (W2R) Pipeline:** The only platform that guarantees zero-landfill waste by intelligently routing unconsumable/expired food to biogas plants and agricultural feeds.
- **AI-Driven Smart Routing:** Built-in logic assigns "urgency" tags based on expiry proximity and quantity, automatically matching highly perishable items with the nearest available volunteers.
- **Unified Ecosystem Architecture:** A single application that seamlessly adapts its UI and functionality based on user roles (Admin, Volunteer, User), reducing fragmentation and onboarding friction.
- **Real-time Backend:** Powered by Firebase (Firestore, Auth) for instant synchronization of donation tasks, statuses, and tracking.
- **Cross-Platform Accessibility:** Built with Flutter, providing a seamless experience across Web, Android, and iOS.


## Assumptions Made
- **Firebase Configuration:** The project assumes a valid Firebase project is set up. The `.env` file must be present in the project directory to supply the API keys safely.
- **Connectivity:** Users are assumed to have stable internet connectivity for real-time updates via Firestore.
- **Location Services:** The mapping feature assumes users grant permission for GPS/Location services.

## Getting Started

### Prerequisites
- Flutter SDK (latest version recommended)
- Dart SDK
- A Firebase project
- A `.env` file containing your Firebase API keys (placed in `main/foodbridge_user/.env`).

### Installation

1. **Clone the project:**
   ```bash
   git clone https://github.com/Satvik42/FoodBridge.git
   cd FoodBridge
   ```

2. **Setup the Unified App:**
   ```bash
   cd main/foodbridge_user
   flutter pub get
   ```

### Running the Application

To run the unified platform (which dynamically routes you to the User, Volunteer, or Admin dashboards based on your login credentials):
```bash
cd main/foodbridge_user
flutter run -d chrome
```

---
*Developed with ❤️ for a Zero-Waste Future.*

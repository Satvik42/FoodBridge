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

## Opportunities
- **Community Empowerment**: Mobilizing local communities, university students, and NGOs to actively participate in food rescue operations with low friction.
- **Cross-Sector Partnerships**: Creating opportunities for collaboration with local governments, waste management facilities, and the agricultural sector (for animal feed/biogas).
- **Actionable Analytics**: Providing restaurants and institutions with valuable data insights regarding their surplus patterns, helping them optimize future food production and reduce costs.

## How different is it from existing ideas?
While most existing food-rescue platforms focus exclusively on human consumption (connecting donors directly to NGOs), FoodBridge introduces a comprehensive, full-lifecycle **Waste-to-Resource (W2R)** pipeline. 

If a listed food item expires or demand is too low, it is not simply deleted from the app and sent to a landfill. Instead, the system autonomously intercepts and redirects it to alternative sustainability streams (like biogas production facilities or farms for animal feed). Furthermore, it consolidates all actors (Donors, Volunteers, Admins) into a **single unified codebase** with dynamic, role-based interfaces, making it drastically easier to maintain and scale.

## How will it be able to solve the problem?
FoodBridge solves the logistical bottlenecks of food redistribution by establishing a real-time, zero-friction network:
- **Speed & Efficiency**: Donors can list surplus in seconds. The AI engine instantly calculates proximity and perishability, matching the food with the nearest available volunteer.
- **Safety & Compliance**: Built-in expiration tracking guarantees food safety. It ensures that expired food is intercepted *before* reaching human consumers, safely utilizing it for secondary sustainability goals.

## USP (Unique Selling Proposition)
- **AI-Driven Waste-to-Resource (W2R) Routing**: The only platform that guarantees zero-landfill waste by intelligently routing unconsumable food to biogas and agricultural feeds.
- **Smart Priority Scoring**: A dynamic algorithm that evaluates expiry proximity and quantity to assign "urgency" tags, ensuring highly perishable items are rescued first.
- **Unified Ecosystem Architecture**: A single application that seamlessly adapts its UI and functionality based on user roles, reducing fragmentation and onboarding friction.

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

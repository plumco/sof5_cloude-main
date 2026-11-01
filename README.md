<!-- File: README.md -->
# Huliot Pipes & Fittings - Sales Order Dashboard

[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Tests](https://img.shields.io/badge/Tests-42%2F42%20Passing-brightgreen?logo=checkmarx&logoColor=white)](#automated-testing)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--Driven-blueviolet)](#architecture)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

> An enterprise-grade, standalone Flutter Web and Mobile application for managing end-to-end Sales Orders (SO), product catalogs, 4-tier role-based approval lifecycles, and dispatch logistics for Huliot Pipes & Fittings Pvt. Ltd.

---

## 📌 Overview

The **Huliot Sales Order Dashboard** streamlines the complex B2B workflow between sales representatives in the field, the commercial back office, warehouse dispatch teams, and executive management.

### Key Capabilities:
- **Product Catalog**: High-performance searchable catalog with DN (diameter nominal), category, and subgroup filtering.
- **Dynamic Pricing Engine**: Real-time discount calculations, cash discount stacking, automatic 18% GST calculation, and MOQ validation.
- **4-Tier Approval Lifecycle**: Clear status state machine (`DRAFT` $\rightarrow$ `PUSHED` $\rightarrow$ `READY_FOR_DISPATCH` $\rightarrow$ `DISPATCHED` / `REVERTED`).
- **Targeted Notification Center**: Push-like targeted alerts delivered exclusively to the creator rep when an order is dispatched or reverted.
- **Reporting & Exports**: Formatted PDF sales order generation and pixel-perfect Excel spreadsheet downloads using official Huliot templates.

---

## 🏛️ Architecture

The project follows a clean, scalable **Feature-Driven Architecture** combined with a robust **Role-Guarded Router**:

```
lib/
├── app/                  # Application root, routing & shell
│   ├── app.dart          # MultiProvider & MaterialApp setup
│   ├── auth_gate.dart    # Firebase Auth state listener
│   ├── dashboard_screen.dart # Main adaptive shell for tabs & views
│   └── router.dart       # Role-based route definitions & navigation guards
├── core/                 # Shared application infrastructure
│   ├── constants/        # Global colors, styling & branding constants
│   ├── errors/           # Failure models & error handling classes
│   ├── services/         # Firebase initialization & bootstrap services
│   └── utils/            # Logging (AppLogger), formatters & helpers
├── features/             # Modular feature packages
│   ├── auth/             # Authentication & user identity
│   ├── catalog/          # Product browsing, filtering & catalog models
│   └── orders/           # Cart, Sales Orders, lifecycle tracking & notifications
├── models/               # Backward-compatible model forwarders
├── providers/            # State management layer (ChangeNotifiers)
├── services/             # Cloud Firestore, Excel/PDF export & local cache
├── shared/widgets/       # Common reusable widgets (AppHeader, CartSidebar)
└── theme/                # Enterprise color palette, shadows & typography
```

---

## 👥 Roles & Access Matrix

Access controls are enforced both in the UI view hierarchy and inside the route guards (`AppRouter`):

| Role | Access Scope | Key Permissions & Actions |
| :--- | :--- | :--- |
| **Sales Rep** | Self-created orders | • Browse catalog & add items to cart<br>• Save local drafts<br>• `[ 🚀 Push to Back Office ]` for verification<br>• Receive creator-specific dispatch/revert notifications |
| **Back Office** (`backoffice@gmail.com`) | All `PUSHED` orders | • Commercial review & price verification<br>• `[ ↩ Revert ]` order with correction notes<br>• `[ 📦 Push to Dispatch ]` approved orders |
| **Dispatch Team** (`dispatch@gmail.com`) | All `READY_FOR_DISPATCH` orders | • View customer shipping addresses & line item quantities<br>• `[ ✓ Mark Dispatched ]` with auto-notification to creator rep |
| **Admin** (`admin@gmail.com`) | Master Observer Oversight | • Unrestricted view across all 7 portal tabs & dashboards<br>• Full visibility into company-wide metrics, orders, and KPI summaries |

---

## ⚙️ Setup & Installation

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.5.0`)
- Google Chrome browser (for local Web testing)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)

### 1. Clone & Fetch Dependencies
```bash
# Clone the repository
git clone https://github.com/huliot/sof5_cloude.git
cd sof5_cloude-main/huliot_so_flutter

# Install packages
flutter pub get
```

### 2. Configure Environment
Copy the example environment configuration:
```bash
# Windows PowerShell
Copy-Item .env.example .env

# macOS / Linux
cp .env.example .env
```
Fill in your Firebase credentials in `.env`:
```env
FIREBASE_API_KEY=your_actual_api_key
API_BASE_URL=https://firestore.googleapis.com
```

### 3. Configure Firebase
```bash
flutterfire configure
```

### 4. Run the Application
```bash
# Run locally on Google Chrome
flutter run -d chrome

# Or run via local web server
flutter run -d web-server --web-port=8080
```

### 5. Build for Production Web
```bash
flutter build web --release
```

---

## 🧪 Automated Testing

The project includes unit, chaos/adversarial, security, and end-to-end integration test suites:

```bash
# Run all tests
flutter test
```

### Test Coverage Highlights (28/28 Passing):
- **Core Infrastructure**: Strong failure model contracts (`ServerFailure`, `CacheFailure`, `NetworkFailure`) and production debug logger (`AppLogger`).
- **E2E 4-Tier Order Lifecycle**: Full verification from Sales Rep $\rightarrow$ Back Office Review $\rightarrow$ Dispatch $\rightarrow$ Targeted Creator Alert $\rightarrow$ Admin Oversight.
- **Chaos & Adversarial Security**: Malformed JSON resilience, prevention of unauthorized status transitions, and rapid duplicate action idempotency.
- **Financial Calculation Integrity**: Clamping negative quantities, handling extreme discounts (>100%), and zero-item safety.
- **Role & Route Authorization**: Substring injection defense in email authentication and strict route protection in `AppRouter`.

---

## 📁 Assets Structure

```
assets/
├── data/
│   ├── products.json        # Bundled product catalog
│   ├── lists.json           # Master dropdown options (terms, zones, customers)
│   └── so_template.xlsx     # Official Excel sales order template
├── icons/                   # Vector and raster iconography
└── images/                  # Branding images and logos
```

---

## 📄 License & Proprietary Notice

© 2026 Huliot Pipes & Fittings Pvt. Ltd. All rights reserved.  
Internal proprietary software for authorized sales and administrative personnel only.

# 📱 Farmers Market POS — Flutter App

> Mobile point-of-sale operator app for the Farmers Market Platform.  
> Built with Flutter + Riverpod + GoRouter.

---

## ✨ Features

| Screen | Description |
|---|---|
| **Login** | Email/password auth against the Laravel API |
| **Home Dashboard** | Quick actions, cart summary, user greeting |
| **Farmer Search** | Real-time search by name, ID, or phone |
| **Farmer Detail** | Credit stats, debt progress bars, action buttons |
| **New Farmer** | Create farmer profile with auto-ID generation |
| **Product Browser** | Category chips + product grid |
| **Cart** | Quantity controls, farmer selector, subtotal |
| **Checkout** | Cash/credit toggle, interest calculation, confirmation |
| **Repayment** | Commodity type + kg input + live FCFA preview + FIFO settlement |

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+ (`flutter --version`)
- Android Studio / VS Code with Flutter plugin
- Backend API running at `http://localhost:8000` (or update `app_config.dart`)

### 1. Install dependencies

```bash
cd e:\TechnicalTest\Frontend\farmers_market_pos
flutter pub get
```

### 2. Configure API URL

Edit `lib/config/app_config.dart`:

```dart
// Emulator (Android) — uses 10.0.2.2 to reach host machine
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Physical device — use your machine's local IP
// static const String baseUrl = 'http://192.168.1.x:8000/api';

// Docker or remote server
// static const String baseUrl = 'http://your-server.com/api';
```

### 3. Run the app

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

---

## 📁 Project Structure

```
farmers_market_pos/
├── lib/
│   ├── main.dart                  ← App entry point (Riverpod + Hive init)
│   ├── config/
│   │   ├── app_config.dart        ← API URL, timeouts, constants
│   │   ├── app_theme.dart         ← Material 3 theme (green brand)
│   │   └── router.dart            ← GoRouter with auth guard
│   ├── models/
│   │   └── models.dart            ← All data models (User, Farmer, Product, Debt, CartItem)
│   ├── services/
│   │   └── api_service.dart       ← Dio HTTP client with token injection
│   ├── providers/
│   │   ├── auth_provider.dart     ← Login/logout + secure token storage
│   │   ├── farmer_provider.dart   ← Search, selected farmer, detail+debts
│   │   └── product_provider.dart  ← Categories, products, cart, checkout
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart
│       ├── home/
│       │   └── home_screen.dart
│       ├── farmers/
│       │   ├── farmer_search_screen.dart
│       │   ├── farmer_detail_screen.dart
│       │   └── farmer_form_screen.dart
│       ├── products/
│       │   └── product_browser_screen.dart
│       ├── transactions/
│       │   ├── cart_screen.dart
│       │   └── checkout_screen.dart
│       └── repayments/
│           └── repayment_screen.dart
└── pubspec.yaml
```

---

## 🔄 App Flow

```
Login → Home
           ├── Search Farmer → Farmer Detail → [New Order | Repayment]
           ├── Browse Products → Cart → Checkout (cash/credit)
           ├── New Farmer (form)
           └── Record Repayment (commodity → FIFO debt settlement)
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation with auth guard |
| `dio` | HTTP client with Sanctum token |
| `flutter_secure_storage` | Secure token storage |
| `hive_flutter` | Local cache / offline queue |
| `connectivity_plus` | Network status detection |
| `google_fonts` | Inter typography |
| `intl` | French number formatting (FCFA) |

---

## 🌐 Offline Support

The app is designed for poor connectivity areas:
- API token persisted securely between sessions
- Category and product data cached in Hive
- Transaction queue for offline submission (hook into `offline_queue` Hive box)

---

## 🎨 Design System

- **Primary**: `#2E7D32` (Deep green — agriculture)
- **Accent**: `#FFA000` (Amber — calls to action)
- **Danger**: `#D32F2F` (Red — errors, debt)
- **Font**: Inter (Google Fonts)
- **Design**: Material 3 with cards, chips, and linear progress indicators

---

## 🔑 Test Credentials (after seeding backend)

| Email | Password | Role |
|---|---|---|
| `admin@farmersmarket.ci` | `password` | Admin |
| `bamba@farmersmarket.ci` | `password` | Operator |

# 🌾 Farmers Market Platform — Frontend Architecture

## 📁 Repository Structure

```text
Frontend/
└── farmers_market_pos/     ← Flutter POS app
    ├── lib/
    │   ├── config/                 (theme, router, app_config)
    │   ├── models/                 (all data models)
    │   ├── providers/              (auth, farmer, product/cart)
    │   ├── screens/                (9 screens)
    │   └── services/               (ApiService with Dio)
    ├── pubspec.yaml
    └── README.md
```

## ✅ Architecture Highlights

### Application Structure
- 9 distinct screens: Login, Home, Farmer Search/Detail/Form, Products, Cart, Checkout, Repayment
- **State Management**: Riverpod for reactive state distribution
- **Routing**: GoRouter with auth guard (auto-redirect to login for unauthenticated users)
- **Networking**: Custom `ApiService` wrapper around `Dio` with token interception

### Offline Support & Persistence
- Offline support architecture using Hive boxes
- Connectivity detection for syncing local actions with the remote API

### Design & UI
- Material 3 design implementation with a green agricultural theme
- Real-time FCFA preview on repayment screen
- French number formatting for all financial figures
- Smooth animations for login entrance and cart management (`Dismissible`, `CurvedAnimation`)

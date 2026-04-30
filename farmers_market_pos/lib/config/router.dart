import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/farmers/farmer_search_screen.dart';
import '../screens/farmers/farmer_detail_screen.dart';
import '../screens/farmers/farmer_form_screen.dart';
import '../screens/products/product_browser_screen.dart';
import '../screens/transactions/cart_screen.dart';
import '../screens/transactions/checkout_screen.dart';
import '../screens/repayments/repayment_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.token != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (ctx, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/farmers',
        builder: (ctx, _) => const FarmerSearchScreen(),
      ),
      GoRoute(
        path: '/farmers/new',
        builder: (ctx, _) => const FarmerFormScreen(),
      ),
      GoRoute(
        path: '/farmers/:id',
        builder: (ctx, state) => FarmerDetailScreen(
          farmerId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products',
        builder: (ctx, _) => const ProductBrowserScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (ctx, _) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (ctx, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/repayment',
        builder: (ctx, _) => const RepaymentScreen(),
      ),
    ],
  );
});

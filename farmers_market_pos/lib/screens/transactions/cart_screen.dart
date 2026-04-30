import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart     = ref.watch(cartProvider);
    final farmer   = ref.watch(selectedFarmerProvider);
    final fmt      = NumberFormat.decimalPattern('fr');
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Mon Panier',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (cart.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, notifier),
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppTheme.danger),
              label: const Text('Vider',
                  style: TextStyle(
                      color: AppTheme.danger, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart()
          : Column(children: [
              // ── Farmer selector ─────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _FarmerSelector(farmer: farmer),
              ),
              const Divider(height: 1),

              // ── Cart items ───────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Dismissible(
                      key: Key('cart-${item.product.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          notifier.updateQuantity(item.product.id, 0),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_rounded,
                                color: AppTheme.danger, size: 28),
                            SizedBox(height: 4),
                            Text('Retirer',
                                style: TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(children: [
                          // Product icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.grass_rounded,
                                color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),

                          // Name & price
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(item.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(
                                '${fmt.format(item.product.priceFcfa)} FCFA / ${item.product.unit}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ]),
                          ),

                          // Qty controls
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              _QtyBtn(
                                icon: Icons.remove_rounded,
                                onTap: () => notifier.updateQuantity(
                                    item.product.id, item.quantity - 1),
                                color: item.quantity <= 1
                                    ? AppTheme.danger
                                    : Colors.grey,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add_rounded,
                                onTap: () => notifier.updateQuantity(
                                    item.product.id, item.quantity + 1),
                                color: AppTheme.primary,
                              ),
                            ]),
                          ),

                          // Subtotal
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${fmt.format(item.subtotal.toInt())}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  fontSize: 14),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // ── Footer ───────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Total à payer',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                '${fmt.format(notifier.subtotal.toInt())} FCFA',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary),
                              ),
                            ]),
                            Text(
                              '${cart.length} article${cart.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pay button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: farmer == null
                              ? null
                              : () => context.push('/checkout'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 20),
                              const SizedBox(width: 8),
                              const Text('Procéder au paiement',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      if (farmer == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Sélectionnez un agriculteur pour continuer',
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ]),
    );
  }

  void _confirmClear(BuildContext context, dynamic notifier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.delete_forever_rounded,
              color: AppTheme.danger, size: 40),
          const SizedBox(height: 12),
          const Text('Vider le panier ?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Tous les articles seront supprimés.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            )),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger),
                onPressed: () {
                  notifier.clear();
                  Navigator.pop(context);
                },
                child: const Text('Vider'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shopping_cart_outlined,
              size: 56, color: AppTheme.primary),
        ),
        const SizedBox(height: 20),
        const Text('Votre panier est vide',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 6),
        const Text('Ajoutez des produits pour commencer',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => GoRouter.of(context).push('/products'),
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: const Text('Parcourir les produits'),
        ),
      ]),
    );
  }
}

// ── Farmer Selector ────────────────────────────────────────────────────────
class _FarmerSelector extends StatelessWidget {
  final dynamic farmer;
  const _FarmerSelector({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: farmer == null
              ? Colors.orange.withOpacity(0.1)
              : AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          farmer == null ? Icons.person_off_outlined : Icons.person_rounded,
          color: farmer == null ? Colors.orange : AppTheme.primary,
          size: 24,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            farmer == null ? 'Aucun agriculteur sélectionné' : farmer.fullName,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: farmer == null ? Colors.orange : null),
          ),
          if (farmer != null)
            Text(
              'Crédit dispo: ${NumberFormat.decimalPattern('fr').format(farmer.creditLimitFcfa)} FCFA',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
        ]),
      ),
      TextButton(
        onPressed: () => GoRouter.of(context).push('/farmers'),
        child: Text(
          farmer == null ? 'Choisir' : 'Changer',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }
}

// ── Qty Button ─────────────────────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

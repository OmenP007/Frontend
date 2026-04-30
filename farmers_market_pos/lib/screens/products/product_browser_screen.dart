import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/product_provider.dart';
import '../../config/app_theme.dart';

class ProductBrowserScreen extends ConsumerWidget {
  const ProductBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats     = ref.watch(categoriesProvider);
    final selCat   = ref.watch(selectedCategoryProvider);
    final products = ref.watch(productsProvider);
    final cart     = ref.watch(cartProvider);
    final fmt      = NumberFormat.decimalPattern('fr');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          selCat?.name ?? 'Produits',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Stack(alignment: Alignment.center, children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.push('/cart'),
            ),
            if (cart.isNotEmpty)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppTheme.accent, shape: BoxShape.circle),
                  child: Text('${cart.length}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // Category chips
        cats.when(
          loading: () => _ShimmerChips(),
          error: (e, _) => const SizedBox.shrink(),
          data: (categories) => Container(
            color: Colors.white,
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final isAll = selCat == null;
                    return _CategoryChip(
                      label: 'Tous',
                      isSelected: isAll,
                      onTap: () =>
                          ref.read(selectedCategoryProvider.notifier).state = null,
                    );
                  }
                  final cat = categories[i - 1];
                  return _CategoryChip(
                    label: cat.name,
                    isSelected: selCat?.id == cat.id,
                    onTap: () =>
                        ref.read(selectedCategoryProvider.notifier).state = cat,
                  );
                },
              ),
            ),
          ),
        ),

        // Divider
        const Divider(height: 1),

        // Products grid
        Expanded(
          child: products.when(
            loading: () => _ShimmerGrid(),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
              ]),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('Aucun produit dans cette catégorie',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.80,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final product = items[i];
                  final inCart = cart.any((c) => c.product.id == product.id);
                  return _ProductCard(
                    name: product.name,
                    price: '${fmt.format(product.priceFcfa)} FCFA',
                    unit: product.unit,
                    inCart: inCart,
                    onAdd: () {
                      ref.read(cartProvider.notifier).addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text('${product.name} ajouté'),
                          ]),
                          duration: const Duration(milliseconds: 1500),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Category Chip ──────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF0F4F2),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF444444),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final String name;
  final String price;
  final String unit;
  final bool inCart;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.unit,
    required this.inCart,
    required this.onAdd,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.inCart
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.06),
                      AppTheme.primaryLight.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(children: [
                  const Center(
                    child: Icon(Icons.grass_rounded,
                        color: AppTheme.primary, size: 44),
                  ),
                  if (widget.inCart)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('✓ Panier',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
              ),
            ),

            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            widget.price,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                          Text('/ ${widget.unit}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 10)),
                        ]),
                        GestureDetector(
                          onTapDown: (_) => _ctrl.forward(),
                          onTapUp: (_) {
                            _ctrl.reverse();
                            widget.onAdd();
                          },
                          onTapCancel: () => _ctrl.reverse(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.inCart
                                  ? AppTheme.primaryLight
                                  : AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              widget.inCart
                                  ? Icons.add_rounded
                                  : Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Loading ────────────────────────────────────────────────────────
class _ShimmerChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) => Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.80,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

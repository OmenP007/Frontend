import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../config/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _waveCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.linear);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final cart = ref.watch(cartProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Animated Header ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                elevation: 0,
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                actions: [
                  Stack(alignment: Alignment.center, children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () => context.push('/cart'),
                    ),
                    if (cart.isNotEmpty)
                      Positioned(
                        top: 6, right: 6,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: AppTheme.accent, shape: BoxShape.circle),
                          child: Text('${cart.length}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: AnimatedBuilder(
                    animation: _waveAnim,
                    builder: (_, child) => Stack(children: [
                      // Hero image background
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/hero_bg.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient base
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xF5081C15), Color(0xEE1B4332), Color(0xCC2D6A4F)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      // Animated wave blobs
                      Positioned(
                        top: -60 + math.sin(_waveAnim.value * math.pi * 2) * 15,
                        right: -80 + math.cos(_waveAnim.value * math.pi * 2) * 10,
                        child: Container(
                          width: 200, height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryLight.withOpacity(0.18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40 + math.cos(_waveAnim.value * math.pi * 2) * 12,
                        left: -50,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withOpacity(0.12),
                          ),
                        ),
                      ),
                      // Decorative icons
                      ...List.generate(6, (i) {
                        final icons = [Icons.grass_rounded, Icons.eco_rounded,
                          Icons.local_florist_rounded, Icons.park_rounded,
                          Icons.agriculture_rounded, Icons.forest_rounded];
                        final rng = math.Random(i * 3);
                        final x = rng.nextDouble() * 300;
                        final y = rng.nextDouble() * 200;
                        final floatY = math.sin((_waveAnim.value + i * 0.2) * math.pi * 2) * 8;
                        return Positioned(
                          left: x, top: y + floatY,
                          child: Opacity(
                            opacity: 0.07,
                            child: Icon(icons[i], size: 24, color: Colors.white),
                          ),
                        );
                      }),
                      child!,
                    ]),
                    child: SafeArea(
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(children: [
                                  // Avatar
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primaryLight, AppTheme.primary],
                                      ),
                                      border: Border.all(color: Colors.white30, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.primary.withOpacity(0.4),
                                            blurRadius: 12, spreadRadius: 2),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        (user?.name.isNotEmpty == true)
                                            ? user!.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                            fontSize: 24, color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('$greeting 👋',
                                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                      Text(user?.name ?? '—',
                                          style: const TextStyle(color: Colors.white,
                                              fontSize: 22, fontWeight: FontWeight.w900)),
                                    ]),
                                  ),
                                  // Date badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(children: [
                                      Text(
                                        _dayName(),
                                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${DateTime.now().day}',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                    ]),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.accent.withOpacity(0.3), AppTheme.accent.withOpacity(0.1)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.verified_rounded, color: AppTheme.accentLight, size: 12),
                                    const SizedBox(width: 6),
                                    Text(
                                      (user?.role ?? '').toUpperCase(),
                                      style: const TextStyle(color: AppTheme.accentLight,
                                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Cart banner ──────────────────────────────────────────────
              if (cart.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _CartBanner(cart: cart),
                  ),
                ),

              // ── Section title ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Row(children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryLight, AppTheme.primary],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Actions rapides',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                  ]),
                ),
              ),

              // ── Action cards grid ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _StaggeredCard(
                      index: 0,
                      controller: _cardsCtrl,
                      child: _ActionCard(
                        icon: Icons.people_alt_rounded,
                        label: 'Agriculteurs',
                        sublabel: 'Rechercher & gérer',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/farmers'),
                      ),
                    ),
                    _StaggeredCard(
                      index: 1,
                      controller: _cardsCtrl,
                      child: _ActionCard(
                        icon: Icons.storefront_rounded,
                        label: 'Produits',
                        sublabel: 'Parcourir le catalogue',
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/products'),
                      ),
                    ),
                    _StaggeredCard(
                      index: 2,
                      controller: _cardsCtrl,
                      child: _ActionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Nouvel Agriculteur',
                        sublabel: 'Créer un compte',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/farmers/new'),
                      ),
                    ),
                    _StaggeredCard(
                      index: 3,
                      controller: _cardsCtrl,
                      child: _ActionCard(
                        icon: Icons.payments_rounded,
                        label: 'Remboursement',
                        sublabel: 'Enregistrer un paiement',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        onTap: () => context.push('/repayment'),
                      ),
                    ),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.4,
                  ),
                ),
              ),
            ],
          ),

          // ── Floating action button (cart) ──────────────────────────────
          if (cart.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 20,
              child: _FloatingCartButton(cart: cart),
            ),
        ],
      ),
    );
  }

  String _dayName() {
    const days = ['DIM', 'LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM'];
    return days[DateTime.now().weekday % 7];
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Se déconnecter ?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 6),
          const Text('Vous serez redirigé vers la page de connexion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
                child: const Text('Déconnecter'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Staggered card animation wrapper ───────────────────────────────────────
class _StaggeredCard extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;

  const _StaggeredCard({
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = index * 0.15;
    final end = (start + 0.55).clamp(0.0, 1.0);
    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOut)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOutCubic)));
    final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOutBack)));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}

// ── Action Card ─────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
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
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background decorative circle
              Positioned(
                right: -20, bottom: -20,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 10, top: -30,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8, offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: widget.gradient.colors.first,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(widget.label,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(widget.sublabel,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cart Banner ─────────────────────────────────────────────────────────────
class _CartBanner extends StatelessWidget {
  final List<dynamic> cart;
  const _CartBanner({required this.cart});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.fold(0.0, (s, i) => s + (i.subtotal as double));
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/cart'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentLight, AppTheme.accent],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${cart.length} article${cart.length > 1 ? 's' : ''} dans le panier',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${subtotal.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ),
        ]),
      ),
    );
  }
}

// ── Floating Cart Button ────────────────────────────────────────────────────
class _FloatingCartButton extends StatefulWidget {
  final List<dynamic> cart;
  const _FloatingCartButton({required this.cart});

  @override
  State<_FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends State<_FloatingCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bounce = Tween<double>(begin: 0.0, end: -8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => context.push('/cart'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentLight, AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.5),
                blurRadius: 20, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${widget.cart.length} article${widget.cart.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
